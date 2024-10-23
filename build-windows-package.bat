@echo on

call dart run flutter_iconpicker:generate_packs

dart run msix:create

REM call dart run msix:create --architecture x64
REM call dart run msix:create --architecture arm64
