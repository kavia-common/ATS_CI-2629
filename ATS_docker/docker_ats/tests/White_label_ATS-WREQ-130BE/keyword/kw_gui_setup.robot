*** Settings ***
Documentation     GUI setup and interaction keywords for DUT web interface.
...               This file consolidates GUI-related automation used across test keywords.
...               
...               Categories:
...               - Authentication: Login GUI to DUT
...               - Navigation: Navigate to dashboard/status pages (stubs for future expansion)
...               - Read/Assert: Read elements and assert states, including WAN IP validation
...               - Browser Lifecycle: Open/Close browser and safe wait helpers
...               - Composite Flow: Retry Get DUT WAN IP Via GUI (expanded docstring)
...               
...               Expanded Summary (Retry Internals):
...               The composite keyword Retry Get DUT WAN IP Via GUI encapsulates:
...                 1) Login GUI -> using Open Browser To DUT and entering credentials.
...                    - Includes retry-friendly waits for GUI elements and login state.
...                 2) Safe sleep: 4 seconds to allow dashboard widgets to fully load.
...                 3) Read WAN IP element: id=dashboard_internet_address via Get Element Text By Locator.
...                    - Retrieval uses retry protection and visibility checks.
...                 4) Safe sleep: 1 second stabilization delay.
...                 5) Close Browser (always): Browser close with ignore errors to avoid leakage between retries.
...                 6) Validation: Assert WAN IP Not Zero (not '0.0.0.0').
...                    - Intended to be run under 'Wait Until Keyword Succeeds' by callers.
...               Notes:
...               - All steps are idempotent and safe for retries.
...               - The composite returns the WAN IP string as result.
...               - Use with: Wait Until Keyword Succeeds   1 min   5 sec   Retry Get DUT WAN IP Via GUI   ${URL}   ${DUT_Password}
Library           SeleniumLibrary
Resource          ./Variable.robot

*** Variables ***
${DEFAULT_BROWSER}          chrome
${DASHBOARD_WAN_LOCATOR}    id=dashboard_internet_address
${LOGIN_USERNAME_LOCATOR}   id=username
${LOGIN_PASSWORD_LOCATOR}   id=password
${LOGIN_SUBMIT_LOCATOR}     css=button[type="submit"]
${POST_LOGIN_ANCHOR}        id=dashboard_main_container

*** Keywords ***
# =========================
# Authentication
# =========================
# PUBLIC_INTERFACE
Login GUI
    [Documentation]    Log into the DUT GUI.
    ...                Arguments:
    ...                - URL: Base URL of the DUT GUI (e.g., http://192.168.11.1/)
    ...                - Password: DUT admin password (username is optional if UI requires).
    ...                - Browser: Optional browser type (default: ${DEFAULT_BROWSER}).
    ...                
    ...                Behavior:
    ...                - Opens browser to URL (or reuses an existing session if open).
    ...                - Fills login credentials and submits.
    ...                - Waits for a post-login anchor element to appear.
    ...                
    ...                Retry notes:
    ...                - Uses visible waits before typing/submit.
    [Arguments]        ${URL}    ${DUT_Password}    ${Browser}=${DEFAULT_BROWSER}
    Open Browser To DUT    ${URL}    ${Browser}
    Wait Until Page Contains Element    ${LOGIN_PASSWORD_LOCATOR}    timeout=15s
    Run Keyword And Ignore Error    Wait Until Page Contains Element    ${LOGIN_USERNAME_LOCATOR}    timeout=2s
    ${has_user}=    Run Keyword And Return Status    Page Should Contain Element    ${LOGIN_USERNAME_LOCATOR}
    IF    ${has_user}
        Focus    ${LOGIN_USERNAME_LOCATOR}
        Clear Element Text    ${LOGIN_USERNAME_LOCATOR}
        Input Text    ${LOGIN_USERNAME_LOCATOR}    admin
    END
    Focus    ${LOGIN_PASSWORD_LOCATOR}
    Clear Element Text    ${LOGIN_PASSWORD_LOCATOR}
    Input Password    ${LOGIN_PASSWORD_LOCATOR}    ${DUT_Password}
    Click Element    ${LOGIN_SUBMIT_LOCATOR}
    Wait Until Page Contains Element    ${POST_LOGIN_ANCHOR}    timeout=20s

# =========================
# Navigation (stubs for expansion)
# =========================
# PUBLIC_INTERFACE
Go To Dashboard
    [Documentation]    Navigate to the main dashboard page after login. Stub for future deep linking or menu navigation.
    ...                Currently assumes landing on dashboard after login; performs a sanity wait.
    Wait Until Page Contains Element    ${POST_LOGIN_ANCHOR}    timeout=10s

# =========================
# Read/Assert Helpers
# =========================
# PUBLIC_INTERFACE
Get Element Text By Locator
    [Documentation]    Return the text content of an element identified by a locator.
    ...                Performs visibility wait before retrieval to be retry-friendly.
    [Arguments]        ${locator}    ${timeout}=10s
    Wait Until Page Contains Element    ${locator}    timeout=${timeout}
    ${visible}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${locator}    ${timeout}
    Run Keyword If    not ${visible}    Safe Sleep    0.5s
    ${text}=    Get Text    ${locator}
    [Return]    ${text}

# PUBLIC_INTERFACE
Read WAN IP From Dashboard
    [Documentation]    Read the WAN IP text from the dashboard widget using ${DASHBOARD_WAN_LOCATOR}.
    ${wan_ip}=    Get Element Text By Locator    ${DASHBOARD_WAN_LOCATOR}    15s
    [Return]    ${wan_ip}

# PUBLIC_INTERFACE
Assert WAN IP Not Zero
    [Documentation]    Assert that the WAN IP is not the placeholder '0.0.0.0'.
    [Arguments]        ${wan_ip}
    Should Not Be Equal    ${wan_ip}    0.0.0.0    msg=Expected a valid WAN IP, got ${wan_ip}

# =========================
# Browser Lifecycle
# =========================
# PUBLIC_INTERFACE
Open Browser To DUT
    [Documentation]    Open the browser to DUT URL with the specified browser type (default: ${DEFAULT_BROWSER}).
    [Arguments]        ${URL}    ${Browser}=${DEFAULT_BROWSER}
    ${session_open}=    Run Keyword And Return Status    Switch Browser    1
    Run Keyword If    not ${session_open}    Open Browser    ${URL}    ${Browser}
    ...    options=add_argument(--no-sandbox);add_argument(--disable-dev-shm-usage)
    Run Keyword If    ${session_open}    Go To    ${URL}
    Maximize Browser Window
    Wait Until Page Contains    ${URL.split('://')[-1].split('/')[0]}    timeout=5s

# PUBLIC_INTERFACE
Close Browser Safely
    [Documentation]    Close the current browser session without failing the test if already closed.
    Run Keyword And Ignore Error    Close All Browsers

# PUBLIC_INTERFACE
Safe Sleep
    [Documentation]    Sleep for a short period allowing GUI to stabilize.
    [Arguments]        ${duration}=1s
    Sleep    ${duration}

# =========================
# Composite Flow
# =========================
# PUBLIC_INTERFACE
Retry Get DUT WAN IP Via GUI
    [Documentation]    Composite flow to retrieve DUT WAN IP via GUI, designed for use with 'Wait Until Keyword Succeeds'.
    ...                Flow:
    ...                 1) Login GUI -> waits for post-login anchor
    ...                 2) Safe Sleep 4s (dashboard load)
    ...                 3) Read WAN IP element (locator: ${DASHBOARD_WAN_LOCATOR})
    ...                 4) Safe Sleep 1s
    ...                 5) Close Browser Safely
    ...                 6) Assert WAN IP Not Zero (not '0.0.0.0')
    ...                Returns: WAN IP string read from the dashboard.
    ...                Usage:
    ...                - Wait Until Keyword Succeeds    1 min    5 sec    Retry Get DUT WAN IP Via GUI    ${URL}    ${DUT_Password}
    [Arguments]        ${URL}    ${DUT_Password}    ${Browser}=${DEFAULT_BROWSER}
    TRY
        Login GUI    ${URL}    ${DUT_Password}    ${Browser}
        Safe Sleep   4s
        ${wan_ip}=   Read WAN IP From Dashboard
        Safe Sleep   1s
    FINALLY
        Close Browser Safely
    END
    Assert WAN IP Not Zero    ${wan_ip}
    [Return]    ${wan_ip}
