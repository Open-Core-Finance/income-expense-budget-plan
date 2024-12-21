REM keytool -genkey -v -keystore .\income-expense-budget-plan-key\android\upload-keystore.jks -storetype pkcs12 -keyalg RSA -keysize 2048 -validity 10000 -alias androidupload
REM keytool -genkey -v -keystore .\income-expense-budget-plan-key\android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias androidupload
REM java -jar .\income-expense-budget-plan-key\android\pepk.jar --keystore=.\income-expense-budget-plan-key\android\upload-keystore.jks --alias=androidupload --output=output.zip --include-cert --rsa-aes-encryption --encryption-key-path=.\income-expense-budget-plan-key\android\encryption_public_key.pem
REM flutter build apk --no-tree-shake-icons
call dart run flutter_iconpicker:generate_packs -a
flutter build appbundle --no-tree-shake-icons --release