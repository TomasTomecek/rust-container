import os
import shutil
import subprocess

import docker
import pytest


IMAGE_NAME=os.environ["IMAGE_NAME"]


@pytest.mark.generic
def test_by_compiling(tmpdir):
    # Travis CI tests are running using user 2000, in container we have user 1000
    # we need to ensure that we can write into the tmp file
    # yes, this is insecure
    print(subprocess.call(["sudo", "chmod", "0777", str(tmpdir)]))
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    helper_files_dir = os.path.join(tests_dir, "files", "compilation")
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
    print(d.logs(container))
    output = subprocess.check_output([os.path.join(str(tmpdir), "main")]).decode("utf-8")
    expected_output = "works\n"
    assert output == expected_output


@pytest.mark.generic
def test_cargo(tmpdir):
    # Travis CI tests are running using user 2000, in container we have user 1000
    # we need to ensure that we can write into the tmp file
    # yes, this is insecure
    print(subprocess.call(["sudo", "chmod", "0777", str(tmpdir)]))
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
        # TODO: create --bin project and run it
        exec_cargo_new = d.exec_create(container, "cargo init")
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


@pytest.mark.clippy
def test_clippy(tmpdir):
    # Travis CI tests are running using user 2000, in container we have user 1000
    # we need to ensure that we can write into the tmp file
    # yes, this is insecure
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    helper_files_dir = os.path.join(tests_dir, "files", "clippy")
    target_dir = os.path.join(str(tmpdir), "project")
    # FIXME: this hack is made so the tests run in travis, should be addressed properly
    print(subprocess.call(["sudo", "chmod", "0777", target_dir]))
    print(subprocess.call(["sudo", "chown", "1000:1000", target_dir]))
    shutil.copytree(helper_files_dir, target_dir)

    d = docker.APIClient(version="auto")
    container = d.create_container(
        IMAGE_NAME,
        command="cargo clippy",
        volumes=['/src'],
        host_config=d.create_host_config(
            binds={
                target_dir: {
                    'bind': '/src',
                    'mode': 'rw'
                }
            }
        )
    )
    d.start(container)
    d.wait(container)
    logs = d.logs(container).decode('utf-8')
    print(repr(logs))
    expected_output = (
        "   Compiling clippy-test v0.0.1 (file:///src)\n"
        "warning: you seem to be trying to use match for destructuring a single pattern. Consider using `if let`\n"
        " --> src/main.rs:3:5\n"
        "  |\n"
        "3 | /     match x {\n"
        "4 | |         Some(y) => println!(\"{:?}\", y),\n"
        "5 | |         _ => ()\n"
        "6 | |     }\n"
        "  | |_____^ help: try this `if let Some(y) = x { $ crate :: io :: _print ( format_args ! ( $ ( $ arg ) * ) ) }`\n"
        "  |\n"
        "  = note: #[warn(single_match)] on by default\n"
        "  = help: for further information visit https://github.com/Manishearth/rust-clippy/wiki#single_match"
    )
    print(repr(expected_output))
    assert expected_output in logs
    print(subprocess.call(["sudo", "chown", "-R", "travis:travis", target_dir]))
    # no need to compile again
    # binary_path = os.path.join(target_dir, "target", "debug", "clippy-test")
    # output = subprocess.check_output([binary_path]).decode("utf-8")
    # expected_output = "1\n"
    # assert output == expected_output
