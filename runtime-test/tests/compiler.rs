#[test]
fn director_compilation_cases() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap();
    let status = std::process::Command::new("node")
        .arg(root.join("test/e2e.mjs"))
        .env("DIRECTOR_TEST_RUNNER", env!("CARGO_BIN_EXE_director-runtime-test"))
        .status().expect("run Director assertions");
    assert!(status.success(), "Director compiler behavioral assertions failed");
}
