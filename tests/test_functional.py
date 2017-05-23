import os
import shutil
import subprocess

import docker


def test_by_compiling(tmpdir):
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    helper_files_dir = os.path.join(tests_dir, "files")
    rust_source_file = os.path.join(helper_files_dir, "main.rs")
    shutil.copy2(rust_source_file, str(tmpdir))

    d = docker.APIClient()
    container = d.create_container(
        "tt/rust",
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
