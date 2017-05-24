import os
import shutil
import subprocess

import docker


IMAGE_NAME=os.environ["IMAGE_NAME"]


def test_by_compiling(tmpdir):
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    helper_files_dir = os.path.join(tests_dir, "files")
    rust_source_file = os.path.join(helper_files_dir, "main.rs")
    shutil.copy2(rust_source_file, str(tmpdir))

    d = docker.APIClient(version="auto")
    container = d.create_container(
        IMAGE_NAME,
        command="rustc ./main.rs",
        volumes=['/src'],
        host_config=d.create_host_config(
            binds={
                str(tmpdir): {
                    'bind': '/src',
                    'mode': 'rw'
                }
            }
        )
    )
    d.start(container)
    d.wait(container)
    output = subprocess.check_output([os.path.join(str(tmpdir), "main")]).decode("utf-8")
    expected_output = "works\n"
    assert output == expected_output


def test_cargo(tmpdir):
    d = docker.APIClient(version="auto")
    container = d.create_container(
        IMAGE_NAME,
        command="sleep 99999",
        volumes=['/src'],
        host_config=d.create_host_config(
            binds={
                str(tmpdir): {
                    'bind': '/src',
                    'mode': 'rw'
                }
            }
        )
    )
    d.start(container)
    try:
        exec_cargo_new = d.exec_create(container, "bash -l -c 'cargo init'")
        output = d.exec_start(exec_cargo_new).decode("utf-8")
        assert "Created library project" in output
        exec_inspect = d.exec_inspect(exec_cargo_new)
        assert exec_inspect["ExitCode"] == 0

        exec_add_libc_dep = d.exec_create(container, 'bash -c \'echo libc = \\\"*\\\" >>Cargo.toml\'')
        output = d.exec_start(exec_add_libc_dep).decode("utf-8")
        exec_inspect = d.exec_inspect(exec_add_libc_dep)
        assert exec_inspect["ExitCode"] == 0

        exec_cargo_build = d.exec_create(container, "cargo build")
        output = d.exec_start(exec_cargo_build).decode("utf-8")
        assert "Finished dev [unoptimized + debuginfo] target(s) in" in output
        assert "Compiling libc" in output
        exec_inspect = d.exec_inspect(exec_cargo_build)
        assert exec_inspect["ExitCode"] == 0
    finally:
        d.kill(container)
