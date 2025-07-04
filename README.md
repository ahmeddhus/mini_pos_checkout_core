# Mini-POS Checkout Core

## Flutter & Dart Versions
- Flutter: 3.24.5, 3.32.5
- Dart: ^3.5.4

## How to Run Tests & View Coverage
Run the provided script:
```sh
chmod +x test_coverage.sh
./test_coverage.sh
```
This will:
- Run all unit tests (you should see: `All tests passed!`)
- Generate an HTML coverage report
- Open the report in your browser (you should see 100% coverage for all business logic files)

## Time Spent
- Implementation: ~2 hours
- Tests & polish: ~1 hour

## Finished Items
- 100% test coverage for all business logic
- BLoC event/state management
- Undo/redo, hydration, value equality
- Robust error handling and edge case coverage
- Full documentation with doc comments
- Clean, modular folder structure

- **All optional features implemented:**
  - Undo/redo last N cart actions
  - Hydration with hydrated_bloc
  - 100% line coverage
  - Money extension (`asMoney`)

## Skipped Items
- No UI (per requirements)
- No database or plugins
- No integration with external services
