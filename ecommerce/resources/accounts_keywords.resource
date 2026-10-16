*** Settings ***
Documentation     Given / When / Then keywords for the Accounts module (registration, login, logout, guest checkout).
...               Each keyword states one user action or one expected outcome in plain language.
...               Locators and test-data setup are kept in this file, so the test cases stay readable.
Library           SeleniumLibrary
Library           Process

*** Variables ***
${BASE_URL}          http://127.0.0.1:8000
${APP_DIR}           .
${PYTHON}            python3
${BROWSER}           chrome
${CHROMEDRIVER}      chromedriver
${CHROME_OPTIONS}    add_argument("--no-sandbox");add_argument("--disable-dev-shm-usage")
${LOGIN_PATH}        /login/
${REGISTER_PATH}     /register/

*** Keywords ***
# ---------- Test setup and teardown ----------
Start Visitor Browser
    [Documentation]    Opens a fresh browser for each test, so no test depends on an earlier one.
    Open Browser    ${BASE_URL}/    ${BROWSER}    options=${CHROME_OPTIONS}    executable_path=${CHROMEDRIVER}
    Set Selenium Timeout    10s

Close Visitor Browser
    Close All Browsers

Run Django Shell
    [Arguments]    ${code}
    ${result}=    Run Process    ${PYTHON}    manage.py    shell    -c    ${code}    cwd=${APP_DIR}
    Should Be Equal As Integers    ${result.rc}    0    msg=Django shell failed: ${result.stderr}
    RETURN    ${result.stdout.strip()}

# ---------- Given: test data ----------
no account exists for "${email}"
    Run Django Shell    from accounts.models import User; User.objects.filter(email='${email}').delete()

a registered account exists for "${email}" with password "${password}"
    Run Django Shell    from accounts.models import User; User.objects.filter(email='${email}').delete(); User.objects.create_user(email='${email}', full_name='Test User', password='${password}', is_active=True)

the visitor has added an available product to the cart
    ${slug}=    Run Django Shell    from products.models import Product; print(Product.objects.filter(active=True).first().slug)
    Go To    ${BASE_URL}/products/${slug}/
    Click Button    xpath=//button[contains(., 'Add to Cart')]
    Wait Until Page Contains    Checkout    timeout=10s

# ---------- Given / When: navigation and actions ----------
the visitor is on the registration page
    Go To    ${BASE_URL}${REGISTER_PATH}
    Wait Until Page Contains    Register    timeout=10s

the visitor fills in the registration form with "${name}", "${email}", "${password}" and "${confirmation}"
    Input Text    id=id_full_name    ${name}
    Input Text    id=id_email        ${email}
    Input Text    id=id_password1    ${password}
    Input Text    id=id_password2    ${confirmation}

the visitor submits the registration form
    Click Button    xpath=//button[contains(., 'Register')]

the visitor logs in with "${email}" and "${password}"
    Go To    ${BASE_URL}${LOGIN_PATH}
    Input Text    id=id_email       ${email}
    Input Text    id=id_password    ${password}
    Click Button    xpath=//form[@action='/login/']//button

the visitor clicks Logout
    Click Link    xpath=//a[@href='/logout/']

the visitor enters "${email}" as the guest email and continues
    Input Text    xpath=//form[@action='/register/guest/']//input[@name='email']    ${email}
    Click Button    xpath=//form[@action='/register/guest/']//button

the visitor enters a shipping address in "${city}" with postal code "${postcode}"
    Input Text    name=address_line_1    1 Test Street
    Input Text    name=city              ${city}
    Input Text    name=state             NT
    Input Text    name=postal_code       ${postcode}
    Input Text    name=country           Australia
    Click Button    xpath=//form[@action='/checkout/address/create/']//button

the visitor finalises the order
    Click Button    xpath=//button[contains(., 'Finalize Checkout')]

# ---------- Then: expected outcomes ----------
the visitor is taken to the login page
    Wait Until Location Contains    ${LOGIN_PATH}    timeout=10s

the visitor stays on the registration page
    Location Should Contain    ${REGISTER_PATH}

the page shows the message "${message}"
    Wait Until Page Contains    ${message}    timeout=10s

the visitor is logged in and sees the Logout link
    Wait Until Page Contains Element    xpath=//a[@href='/logout/']    timeout=10s

the visitor is not logged in
    Page Should Not Contain Element    xpath=//a[@href='/logout/']

the visitor stays on the login page and is not logged in
    Location Should Contain    ${LOGIN_PATH}
    Page Should Not Contain Element    xpath=//a[@href='/logout/']

the visitor sees the order confirmation
    Wait Until Page Contains    Thank you for your order    timeout=15s