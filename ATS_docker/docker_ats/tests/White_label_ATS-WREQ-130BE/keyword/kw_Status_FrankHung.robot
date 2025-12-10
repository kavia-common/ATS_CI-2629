*** Settings ***
Resource    ./base.robot

*** Variables ***


*** Keywords ***
Verify information is correct on Dual Image page
    ${result}=    get text    id=current
    Should Contain Any    ${result}    1    2
    ${result}=    get text    xpath=//*[@id="tbody_id_0"]/td[1]
    Should Be Equal    ${result}    1
    ${result}=    get text    xpath=//*[@id="tbody_id_0"]/td[2]
    Should Not Be Empty    ${result}
    ${result}=    get text    xpath=//*[@id="tbody_id_1"]/td[1]
    Should Be Equal    ${result}    2
    ${result}=    get text    xpath=//*[@id="tbody_id_1"]/td[2]
    Should Not Be Empty    ${result}

Open Dual Image Page
    click element    id=lang_mainmenu_status
    sleep    1
    click element    id=lang_submenu_status_dualImage
    sleep    4

Verify information is correct on Mesh Client List
    ${result}=    get text    xpath=//*[@id="Device_topology_table_id_0"]/td[1]
    Should Not Be Empty    ${result}
    ${result}=    get text    xpath=//*[@id="Device_topology_table_id_0"]/td[2]
    Should Contain    ${result}    192.168.
    ${result}=    get text    xpath=//*[@id="Device_topology_table_id_0"]/td[3]
    Should Not Be Empty    ${result}
    ${result}=    get text    xpath=//*[@id="Device_topology_table_id_0"]/td[4]
    Should Not Be Empty    ${result}
    ${result}=    get text    xpath=//*[@id="Device_topology_table_id_0"]/td[5]
    Should Contain Any    ${result}    ETHER    WLAN
    [Teardown]    Close Browser


Verify information is correct on Mesh Node List
    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[1]
    Should Not Be Empty    ${result}

    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[2]
    Should Contain    ${result}    192.168.

    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[3]
    Should Not Be Empty    ${result}

    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[4]
    Should Not Be Empty    ${result}

    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[5]
    Should Not Be Empty    ${result}

    ${result}=    get text    xpath=//*[@id="Mesh_topology_table_id_0"]/td[6]
    Should Be Equal    ${result}    Controller



Verify shall shows 6G companion devices
    click element    id=scan_6g
    sleep    40
    ${result}=    get text    id=result_6g
    log    ${result}
    Should Contain    ${result}    WPA
    Should Contain    ${result}    PSK
    Close Browser

Verify shall shows 5G companion devices
    click element    id=scan_5g
    sleep    40
    ${result}=    get text    id=result_5g
    log    ${result}
    Should Contain    ${result}    WPA
    Should Contain    ${result}    PSK
    Close Browser

Verify shall shows 2.4G companion devices
    click element    id=scan_2g
    sleep    40
    ${result}=    get text    id=result_2g
    log    ${result}
    Should Contain    ${result}    WPA
    Should Contain    ${result}    PSK
    Close Browser

Open WiFi Neighbor Page
    click element    id=menu_status
    sleep    1
    click element    id=lang_submenu_status_wifiNeighbor
    sleep    4

Open LAN Status Page
    click element    id=menu_status
    sleep    1
    click element    id=menu_status_lan
    sleep    4

Open WAN Status Page
    click element    id=menu_status
    sleep    1
    click element    id=menu_status_wan
    sleep    4

Setup DUT to Bridge Mode
    click element    id=lang_mainmenu_basic_setting
    sleep    1
    click element    id=menu_basic_setting_wan
    sleep    2
    Select From List By Value    id=wan_mode    bridge
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    200
    Reload Page
    sleep    10

Setup PPPoE connection behind Login Status
    click element    id=lang_mainmenu_basic_setting
    sleep    1
    click element    id=menu_basic_setting_wan
    sleep    2
    click element    id=lang_ppp
    sleep    1
    input text    id=ppp_name    cisco
    sleep    1
    input text    id=ppp_pwd    cisco
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    200
    Reload Page
    sleep    10


Setup Static connection
    click element    id=lang_mainmenu_basic_setting
    sleep    1
    click element    id=menu_basic_setting_wan
    sleep    2
    click element    id=lang_static
    sleep    1
    input text    id=static_ip    172.16.11.111
    sleep    1
    input text    id=static_mask    255.255.255.0
    sleep    1
    input text    id=static_gatway    172.16.11.1
    sleep    1
    input text    id=static_dns1    8.8.8.8
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    200
    Reload Page
    sleep    10

Verify the status of Internet Connection is correct with DHCP mode
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[2]
    Should Contain    ${message}    dhcp
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[4]
    Should Contain    ${message}    connected
    sleep    1
    click element    //*[@id="status_wan_ipv4_table_id_0"]/td[5]/button/img
    sleep    2
    ${result}=    Get Text    id=type_diag
    Should Contain    ${result}    dhcp
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    172.16.11.
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    172.16.11.1
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    168.95.1.1
    ${result}=    Get Text    id=mask_diag
    Should Contain    ${result}    255.255.255.0
    ${result}=    Get Text    id=status_diag
    Should Contain Any    ${result}    connected    Connected
    click element    id=leafconfirm
    sleep    2
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep   2
    ${result}=    Get Text    id=type_diag
    Should Contain Any    ${result}    dhcp   DHCP
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:5678:9abc:
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    [Teardown]    close browser

Verify the status of Internet connection is correct with Static IP Mode
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[2]
    Should Contain    ${message}    static
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[4]
    Should Contain    ${message}    connected
    sleep    1
    click element    //*[@id="status_wan_ipv4_table_id_0"]/td[5]/button/img
    sleep    2
    ${result}=    Get Text    id=type_diag
    Should Contain    ${result}    static
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    172.16.11.
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    172.16.11.1
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    8.8.8.8
    ${result}=    Get Text    id=mask_diag
    Should Contain    ${result}    255.255.255.0
    ${result}=    Get Text    id=status_diag
    Should Contain Any    ${result}    connected    Connected
    click element    id=leafconfirm
    sleep    2
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep   2
    ${result}=    Get Text    id=type_diag
    Should Contain Any    ${result}    Static    static
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    ::
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    ::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    ::
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    [Teardown]    close browser

Check GUI ipv4 status
    Login GUI    ${URL}    ${DUT_Password}
    Open status page
    ${message}=    Get Text    id=ipv4type1
    Should Contain    ${message}    static
    sleep    1
    ${message}=    Get Text    id=ipv4status1
    Should Contain    ${message}    Connected
    sleep    1

Verify the status of Internet Connection is correct with PPPoE mode
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[2]
    Should Contain    ${message}    pppoe
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[4]
    Should Contain    ${message}    connected
    sleep    1
    click element    //*[@id="status_wan_ipv4_table_id_0"]/td[5]/button/img
    sleep    2
    ${result}=    Get Text    id=type_diag
    Should Contain    ${result}    pppoe
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    172.
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    50.
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    168.95.1.1
    ${result}=    Get Text    id=mask_diag
    Should Contain    ${result}    255.255.255.255
    ${result}=    Get Text    id=status_diag
    Should Contain Any    ${result}    connected    Connected
    click element    id=leafconfirm
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep   2
    ${result}=    Get Text    id=type_diag
    Should Contain Any    ${result}    PPPoE    pppoe
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:5678:9abc:
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    [Teardown]    close browser

Verify the status of Internet Connection is correct with Bridge mode
    click element    id=lang_mainmenu_status
    sleep    2
    click element    id=menu_status_wan
    sleep    4
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[2]
    Should Contain    ${message}    bridge
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_wan_ipv4_table_id_0"]/td[4]
    Should Contain    ${message}    connected
    sleep    1
    [Teardown]    Close Browser

Verify the status of Local Network is correct
    ${message}=    Get Text    xpath=//*[@id="status_lan_host_table_id_0"]/td[1]
    Should Contain    ${message}    192.168.1.
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_lan_host_table_id_0"]/td[2]
    Should Contain    ${message}    255.255.255.0
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_lan_host_table_id_0"]/td[3]
    Should Contain    ${message}    192.168.1.1
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_lan_host_table_id_0"]/td[4]
    Should Contain    ${message}    fe80::
    ${message}=    Get Text    xpath=//*[@id="status_lan_host_table_id_0"]/td[5]
    Should Contain    ${message}    ${DUT_LAN_MAC}
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_0"]/td[2]
    Should Contain    ${message}    Down
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_1"]/td[2]
    Should Contain    ${message}    Down
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_2"]/td[2]
    Should Contain    ${message}    Up
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_3"]/td[2]
    Should Contain    ${message}    Up
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_2"]/td[3]
    Should Contain    ${message}        1000(Mbps)
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_3"]/td[3]
    Should Contain    ${message}        1000(Mbps)
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_2"]/td[4]
    Should Contain Any    ${message}    full    Full
    ${message}=    Get Text    xpath=//*[@id="status_lan_table_id_3"]/td[4]
    Should Contain Any    ${message}    full    Full
    [Teardown]    Close Browser

get MAC from host
    [Arguments]    ${host}
    ${getMAC}=    cli    ${host}    ifconfig ${DEVICES.${host}.interface} | grep "ether"
    @{getMAC}=    Get Regexp Matches    ${getMAC}    (?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})
    ${getMAC}=    Strip String    ${getMAC}[0]
    [Return]    ${getMAC}


Open basic setup page
    click element    id=lang_mainmenu_basic_setting
    sleep    2
    wait_until_element_is_visible    id=wan_mode    timeout=5

Open status page
    click element    id=lang_mainmenu_status
    sleep    2
    wait_until_element_is_visible    id=ipv4type1    timeout=5
