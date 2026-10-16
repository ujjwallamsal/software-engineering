*** Settings ***
Documentation     Accounts module: register, login, logout, guest checkout.
...               Expected values come from accounts/views.py, accounts/forms.py,
...               ecommerce/urls.py, settings.py and the accounts/carts templates.
Library           SeleniumLibrary
Test Teardown     Close Browser

*** Variables ***
${BROWSER}           Chrome
${BASE_URL}          http://127.0.0.1:8000
${VALID_EMAIL}       testuser@example.com
${VALID_PASSWORD}    SecurePass123!
${WRONG_PASSWORD}    WrongPass999!
${GUEST_EMAIL}       guest@example.com

*** Keywords ***
Log In As Test User
    Open Browser    ${BASE_URL}/login/    ${BROWSER}
    Input Text      id=id_email       ${VALID_EMAIL}
    Input Text      id=id_password    ${VALID_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Login')]
    Wait Until Location Is    ${BASE_URL}/    timeout=10s

*** Test Cases ***
TC-01 Register with valid details
    [Documentation]    A new user registers with a unique email and matching passwords and is sent to the login page (RegisterView.success_url = '/login/')
    Open Browser    ${BASE_URL}/register/    ${BROWSER}
    Input Text      id=id_email        ${VALID_EMAIL}
    Input Text      id=id_password1    ${VALID_PASSWORD}
    Input Text      id=id_password2    ${VALID_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Register')]
    Wait Until Location Is    ${BASE_URL}/login/    timeout=10s

TC-02 Reject duplicate email
    [Documentation]    Registering with an email that already exists shows Django's unique-field error and stays on the register page
    Open Browser    ${BASE_URL}/register/    ${BROWSER}
    Input Text      id=id_email        ${VALID_EMAIL}
    Input Text      id=id_password1    ${VALID_PASSWORD}
    Input Text      id=id_password2    ${VALID_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Register')]
    Wait Until Page Contains    User with this Email already exists.    timeout=10s
    Location Should Contain    /register/

TC-03 Login with valid credentials
    [Documentation]    A registered user logs in and is redirected to the home page, where the Logout link appears in the navbar
    Open Browser    ${BASE_URL}/login/    ${BROWSER}
    Input Text      id=id_email       ${VALID_EMAIL}
    Input Text      id=id_password    ${VALID_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Login')]
    Wait Until Location Is    ${BASE_URL}/    timeout=10s
    Page Should Contain Element    xpath=//a[@href='/logout/']

TC-04 Logout ends the session
    [Documentation]    A logged-in user clicks Logout and is redirected to LOGOUT_REDIRECT_URL (/login/), with the Logout link gone
    Log In As Test User
    Click Link      xpath=//a[@href='/logout/']
    Wait Until Location Is    ${BASE_URL}/login/    timeout=10s
    Page Should Not Contain Element    xpath=//a[@href='/logout/']

TC-05 Guest checkout
    [Documentation]    A shopper with an item in the cart enters only an email on the checkout page and reaches the shipping address step without logging in
    Open Browser    ${BASE_URL}/products/    ${BROWSER}
    Click Link      xpath=(//a[contains(text(), 'View')])[1]
    Wait Until Page Contains Element    xpath=//button[contains(text(), 'Add to Cart')]    timeout=10s
    Click Button    xpath=//button[contains(text(), 'Add to Cart')]
    Sleep    3s
    Go To    ${BASE_URL}/cart/checkout/
    Wait Until Page Contains Element    xpath=//form[@action='/register/guest/']    timeout=10s
    Input Text      xpath=//form[@action='/register/guest/']//input[@name='email']    ${GUEST_EMAIL}
    Click Button    xpath=//form[@action='/register/guest/']//button
    Wait Until Page Contains    Shipping Address    timeout=10s
    Location Should Be    ${BASE_URL}/cart/checkout/
    Page Should Not Contain Element    xpath=//form[@action='/login/']

TC-06 Reject mismatched passwords 
    [Documentation]    Registration fails when the two password fields differ, with the message from RegisterForm.clean_password2
    Open Browser    ${BASE_URL}/register/    ${BROWSER}
    Input Text      id=id_email        newuser@example.com
    Input Text      id=id_password1    ${VALID_PASSWORD}
    Input Text      id=id_password2    ${WRONG_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Register')]
    Wait Until Page Contains    Passwords don't match    timeout=10s
    Location Should Contain    /register/

TC-07 Reject wrong password at login 
    [Documentation]    Login with a wrong password stays on the login page and does not log the user in
    Open Browser    ${BASE_URL}/login/    ${BROWSER}
    Input Text      id=id_email       ${VALID_EMAIL}
    Input Text      id=id_password    ${WRONG_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'Login')]
    Sleep    3s
    Location Should Contain    /login/
    Page Should Not Contain Element    xpath=//a[@href='/logout/']
