# SV/UVM Coding Standards

## Naming Conventions

- Classes: `snake_case` with type suffix (`my_driver`, `apb_transaction`)
- Variables: `snake_case` (`data_valid`, `addr_bus`)
- Constants: `UPPER_SNAKE_CASE` (`MAX_DEPTH`, `DEFAULT_TIMEOUT`)
- Parameters: `UPPER_SNAKE_CASE` (`ADDR_WIDTH`, `DATA_WIDTH`)
- Methods: `snake_case` (`send_request`, `check_response`)
- Files: one class per file, filename matches class name (`my_driver.sv`)

## Code Organization

- Package boundary: group related classes in a package
- Import: use explicit package imports, avoid wildcard `import *`
- Class order: parameters → properties → constraints → methods → extern methods
- One class per file unless tightly coupled inner classes

## UVM Conventions

- Factory registration: always use `uvm_component_utils` / `uvm_object_utils`
- Config_db: use type-safe `get`/`set` with explicit type casting
- Phase: override only phases you need, call `super.phase_name()` first
- Objection: raise/drop in sequence, not in driver/monitor
- TLM: use `uvm_analysis_port` for broadcast, `uvm_*_port` for point-to-point

## Comments

- Every class has a one-line header comment
- Complex constraints have inline comments explaining the intent
- Non-obvious TLM connections have comments explaining the data flow
- No commented-out code in committed files

## Error Handling

- Use `uvm_report_*` for all messages, never `$display`
- Set appropriate verbosity levels: `UVM_LOW` for key events, `UVM_HIGH` for debug
- Use `uvm_fatal` only for unrecoverable errors
- Use `uvm_error` for test failures, `uvm_warning` for recoverable issues
