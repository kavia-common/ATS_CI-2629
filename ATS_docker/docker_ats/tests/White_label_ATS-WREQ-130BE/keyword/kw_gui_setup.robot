*** Settings ***
# Centralized GUI login/setup keywords
# This resource consolidates duplicated Login GUI related keywords that were previously spread across multiple kw_basic_* files.

*** Keywords ***
Login GUI
    [Documentation]    Open the DUT Web GUI and perform login using provided URL and password with retries and standard teardown.
    [Arguments]    ${URL}    ${DUT_Password}
    Wait Until Keyword Succeeds    4x    60s    Retry Login GUI    ${URL}    ${DUT_Password}
    [Teardown]    Stop Test Fail Retry Login Fail

Stop Test Fail Retry Login Fail
    [Documentation]    Guard to fail fast if the expected post-login element is not visible.
    # Some suites expect different elements; check common ones to avoid regressions.
    ${status_basic}=     Run Keyword And Return Status    Wait Until Element Is Visible    id=lang_mainmenu_basic_setting    timeout=5
    ${status_home}=      Run Keyword And Return Status    Wait Until Element Is Visible    id=homepage_tile    timeout=5
    Run Keyword If    ${status_basic} or ${status_home}    No Operation
    ...    ELSE    Fatal Error

Retry Login GUI
    [Documentation]    Internal helper that opens the GUI and logs in via the standard login form.
    [Arguments]    ${URL}    ${DUT_Password}
    Run Keyword And Ignore Error    Close Browser
    Sleep    2
    Open Web GUI    ${URL}
    Sleep    5
    Wait Until Element Is Visible    id=acnt_passwd    timeout=90
    Input Text    id=acnt_username    admin
    Sleep    1
    Input Text    id=acnt_passwd    ${DUT_Password}
    Sleep    1
    Click Element    id=myButton
    Sleep    5
    # Wait for main menu to appear and ajax loader to disappear
    Wait Until Element Is Visible    id=lang_mainmenu_basic_setting    timeout=30
    Sleep    3
    Wait Until Element Is Not Visible    id=ajaxLoaderIcon    timeout=120
    Sleep    2

Open Web GUI
    [Documentation]    Open a browser to the DUT URL and maximize the window after basic network checks.
    [Arguments]    ${URL}
    Run Keyword And Ignore Error    Delete All Cookies
    ${res}=    Run    ifconfig
    Log    ${res}
    ${res}=    Run    ping 192.168.1.1 -c 4
    Log    ${res}
    Open Browser    ${URL}    Firefox
    Sleep    3
    Maximize Browser Window
    Sleep    3

Wizard-Setup
    [Documentation]    Perform initial wizard flow used by some platforms after login.
    [Arguments]    ${URL}    ${DUT_Password}
    Login GUI    ${URL}    ${DUT_Password}
    Click Element    id=next
    Sleep    2
    Input Text    id=new_pwd    admin
    Sleep    1
    Input Text    id=confirm_pwd    admin
    Sleep    1
    Click Element    id=next
    Sleep    1
    ${enable_or_disable}=    Get Element Attribute    id=switch_layout_enable_btn    class
    Log    ${enable_or_disable}
    Sleep    2
    Run Keyword If    '${enable_or_disable}'=='switch hidden-dom-removal'    Click Element    id=switch_layout_enable_btn
    Sleep    2
    Click Element    id=next
    Sleep    1
    Click Element    id=apply
    Sleep    180
    Close Browser

Login and Reset Default DUT
    [Documentation]    Platform-aware login and reset to defaults, including quick-setup on SPF13.
    [Arguments]    ${URL}    ${DUT_Password}
    Wait Until Keyword Succeeds    3x    10s    retry Login and Reset Default DUT    ${URL}    ${DUT_Password}

retry Login and Reset Default DUT
    [Documentation]    Helper for Login and Reset Default DUT; detects platform via ${Platform}.
    [Arguments]    ${URL}    ${DUT_Password}
    IF    ${Platform}=='SPF12'
        Sleep    1
    ELSE IF    ${Platform}=='SPF13'
        Run    echo "vagrant" | sudo -S chmod 777 /dev/ttyUSB0
        ${result}=    cli    DUT_serial_port    rm /opt/feature/GUI-QUICKSETUP-ENABLED && /etc/init.d/device-ui restart    prompt=root@
        Sleep    1
        Log    ${result}
    END
    Login GUI    ${URL}    ${DUT_Password}
    Reset Default DUT
    IF    ${Platform}=='SPF12'
        Sleep    1
    ELSE IF    ${Platform}=='SPF13'
        Wizard-Setup    ${URL}    ${DUT_Password}
    END

Reset Default DUT
    [Documentation]    Navigate to reset page and perform factory reset, then ensure login page appears again.
    Go to Reset to Default Page
    Reset to Default DUT Action

Go to Reset to Default Page
    [Documentation]    Navigate to management reset page (selector variant A).
    Click Element    id=lang_mainmenu_management
    Sleep    2
    Click Element    id=lang_submenu_management_settings
    Sleep    2

Reset to Default DUT Action
    [Documentation]    Execute reset and wait for the device to be back to login-ready state.
    Click Element    id=lang_restore_btn
    Sleep    2
    Click Element    id=confirm_dialog_confirmed
    Sleep    300
    Reload Page
    Wait Until Element Is Visible    id=acnt_passwd    timeout=60
    Sleep    2
    Close Browser
    Sleep    2
