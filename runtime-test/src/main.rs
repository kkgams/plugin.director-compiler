use std::io::{self, Read};
use wasmtime::component::{Component, Linker, ResourceTable};
use wasmtime::{Config, Engine, Result, Store};
use wasmtime_wasi::{WasiCtx, WasiCtxView, WasiView};
use serde_json::json;

wasmtime::component::bindgen!({ path: "../wit", world: "director-compiler-plugin" });

struct State { wasi: WasiCtx, table: ResourceTable }
impl WasiView for State {
    fn ctx(&mut self) -> WasiCtxView<'_> {
        WasiCtxView { ctx: &mut self.wasi, table: &mut self.table }
    }
}

fn main() -> Result<()> {
    let component_path = std::env::args().nth(1).expect("component path required");
    let mut source = String::new();
    io::stdin().read_to_string(&mut source)?;
    let mut config = Config::new();
    config.wasm_component_model(true);
    let engine = Engine::new(&config)?;
    let component = Component::from_file(&engine, component_path)?;
    let mut linker = Linker::new(&engine);
    wasmtime_wasi::p2::add_to_linker_sync(&mut linker)?;
    let mut store = Store::new(&engine, State {
        wasi: WasiCtx::builder().build(), table: ResourceTable::new(),
    });
    let bindings = DirectorCompilerPlugin::instantiate(&mut store, &component, &linker)?;
    let result = bindings.gams_director_compiler_director_compiler().call_compile(&mut store, &source)?;
    let result = match result {
        Ok(ir) => json!({"ok": ir}),
        Err(diagnostics) => json!({"err": diagnostics.iter().map(|d| json!({
            "code": d.code, "message": d.message,
            "span": {
                "start": {"byte-offset": d.span.start.byte_offset, "line": d.span.start.line, "column": d.span.start.column},
                "end": {"byte-offset": d.span.end.byte_offset, "line": d.span.end.line, "column": d.span.end.column}
            }
        })).collect::<Vec<_>>()}),
    };
    println!("{result}");
    Ok(())
}
