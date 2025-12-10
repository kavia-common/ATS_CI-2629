*** Settings ***
Resource    ./base.robot

*** Variables ***


*** Keywords ***
Get DUT WAN IP
    Wait Until Keyword Succeeds    4x    4s    retry Get DUT WAN IP

retry Get DUT WAN IP
    Login GUI    ${URL}    ${DUT_Password}
    sleep    4
    ${result}=    Get Text    id=dashboard_internet_address
    sleep    1
    Close Browser
    Should Not Contain    ${result}    0.0.0.0
    [Return]    ${result}

Verify LAN PC can access WebGUI
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S wget http://192.168.1.1    prompt=vagrant@lanhost    timeout=60
    sleep    2
    Should Contain    ${result}    200 OK

Verify LAN PC can get ip from DUT
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${lanhost_IP}=    Get IP from host    lanhost
    Should Contain    ${lanhost_IP}    192.168.1.

Add an IP 192.168.1.201 to DHCP Reservation, verify GUI show error message
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=edit_reserved_ip
    sleep    2
    click element    id=dhcpreserved_add_btn
    sleep    2
    ${get_lanpc_mac}=    get MAC from host    lanhost
    Input Text    id=dhcpreserved_mac    ${get_lanpc_mac}
    sleep    1
    Input Text    id=dhcpreserved_ip    192.168.1.201
    sleep    1
    click element    id=leafConfirm
    Handle Alert
    sleep    2
    Close All Browsers

Verify the Assign IP Address is Correct on LAN PC
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${lanhost_IP}=    Get IP from host    lanhost
    Should Contain    ${lanhost_IP}    192.168.1.112

Edit Client Name, Assign IP Address and click "Save" button in Clients Already Reserved
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=edit_reserved_ip
    sleep    2
    click element    xpath=//*[@id="lan_dhcpreserved_tbody_id_0"]/td[4]/button[1]/img
    sleep    2
    Input Text    id=dhcpreserved_ip    192.168.1.112
    sleep    1
    click element    id=leafConfirm
    sleep     30
    Close Browser

Verify the information of client are added in the Client Already Reserved
    ${reserved_ip}=    Get Text    xpath=//*[@id="lan_dhcpreserved_tbody_id_0"]/td[3]
    Should Contain    ${reserved_ip}    192.168.1.111
    Close Browser
    ${lanhost_IP}=    Get IP from host    lanhost
    Should Contain    ${reserved_ip}    192.168.1.111

Get IP from host
    [Arguments]    ${host}
    ${getIP}=    cli    ${host}    ifconfig ${DEVICES.${host}.interface} | grep "inet"
    @{getIP}=    Get Regexp Matches    ${getIP}    (\\d+\\.){3}\\d+
    ${getIP}=    Strip String    ${getIP}[0]
    [Return]    ${getIP}

get MAC from host
    [Arguments]    ${host}
    ${getMAC}=    cli    ${host}    ifconfig ${DEVICES.${host}.interface} | grep "ether"
    @{getMAC}=    Get Regexp Matches    ${getMAC}    (?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})
    ${getMAC}=    Strip String    ${getMAC}[0]
    [Return]    ${getMAC}

On Basic Setup > LAN Page, click "DHCP Reservation" button, Enter Client Name, Assign IP Address, To This MAC Address and click "Add" button in Manually Add Client
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=edit_reserved_ip
    sleep    2
    click element    id=dhcpreserved_add_btn
    sleep    2
    ${get_lanpc_mac}=    get MAC from host    lanhost
    Input Text    id=dhcpreserved_mac    ${get_lanpc_mac}
    sleep    1
    Input Text    id=dhcpreserved_ip    192.168.1.111
    sleep    1
    click element    id=leafConfirm
    sleep     30

On Basic Setup > LAN Page, Set IP Address Range 192.168.1.100 to 102
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    192.168.1.1
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    Input Text    id=dhcp_start_input    100
    sleep    1
    Input Text    id=dhcp_end_input    102
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Verify on LAN PC, the DHCP related information is as the setting
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.123.
    ${get_lanIP_end}=    Remove String    ${get_lanIP}    192.168.123.
    ${get_lanIP_end}=    Convert To Integer    ${get_lanIP_end}
    Should Be True    49<${get_lanIP_end}<76
    ${get_lanDNS}=    cli   lanhost    systemctl status systemd-resolved > dns_result_temp.txt    prompt=vagrant@lanhost    timeout=60
    ${get_lanDNS}=    cli   lanhost    cat dns_result_temp.txt
    Should Contain    ${get_lanDNS}    8.8.8.8
    Should Contain    ${get_lanDNS}    168.95.1.1

Set DUT LAN IP address be 192.168.123.1 and change Start IP Address to 192.168.123.50, Maximum Number of Users to 25, Client Lease Time to 3 minutes, DNS(8.8.8.8)
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    192.168.123.1
    sleep    1
    click element    id=lang_manual
    sleep    1
    Input Text    id=dns1    8.8.8.8
    sleep    1
    Input Text    id=dns2    168.95.1.1
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    Input Text    id=dhcp_start_input    50
    sleep    1
    Input Text    id=dhcp_end_input    75
    sleep    1
    Input Text    id=dhcp_lease_input    180
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Enable DUT LAN DHCP v4 Server
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_dhcp_btn    class
    log    ${enable_or_disable}
    sleep    1
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal'    click element    id=switch_layout_dhcp_btn
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Disable DUT LAN DHCP v4 Server
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_dhcp_btn    class
    log    ${enable_or_disable}
    sleep    1
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal checked'    click element    id=switch_layout_dhcp_btn
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Change DUT LAN IP to Default from GUI
    [Arguments]    ${ATS_Server_Network}
    Run    echo 'vagrant' | sudo -S dhclient ${ATS_to_DUT_Interface} -r
    sleep    2
    Run    echo 'vagrant' | sudo -S ip addr add ${ATS_Server_Network}.52/24 dev ${ATS_to_DUT_Interface}
    sleep    2
    Run    echo 'vagrant' | sudo -S ip route add ${ATS_Server_Network}.0/24 via 0.0.0.0 dev ${ATS_to_DUT_Interface}
    sleep    2
    Login GUI    http://${ATS_Server_Network}.1    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    192.168.1.1
    sleep    1
    Input Text    id=mask    255.255.255.0
    sleep    1
    click element    id=lang_proxy
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    Input Text    id=dhcp_start_input    100
    sleep    1
    Input Text    id=dhcp_end_input    200
    sleep    1
    Input Text    id=dhcp_lease_input    86400
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser
    Run    echo 'vagrant' | sudo -S dhclient ${ATS_to_DUT_Interface} -r
    sleep    8
    Run    echo 'vagrant' | sudo -S ip addr add 192.168.1.52/24 dev ${ATS_to_DUT_Interface}
    sleep    2
    Run    echo 'vagrant' | sudo -S ip route add 192.168.1.0/24 via 0.0.0.0 dev ${ATS_to_DUT_Interface}
    sleep    2
    ${ping_result}=    Run    ping 192.168.1.1 -c 4
    Should Contain    ${ping_result}    ttl=

Open LAN Page
    click element    id=lang_mainmenu_basic_setting
    sleep    2
    click element    id=menu_basic_setting_lan
    sleep    2
    wait_until_element_is_visible    id=ip    timeout=10


Change DUT LAN IP adddress and subnet mask config 192.168.0.1/255.255.0.0
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    192.168.0.1
    sleep    1
    Input Text    id=mask    255.255.0.0
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Change DUT LAN IP adddress and subnet mask config 172.56.0.1/255.255.0.0
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    172.56.0.1
    sleep    1
    Input Text    id=mask    255.255.0.0
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Change DUT LAN IP adddress and subnet mask config 10.0.0.1/255.0.0.0
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    10.0.0.1
    sleep    1
    Input Text    id=mask    255.0.0.0
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Change DUT LAN IP adddress and subnet mask config 192.168.2.1/255.255.255.0
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Input Text    id=ip    192.168.2.1
    sleep    1
    Input Text    id=mask    255.255.255.0
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

reset IP
    Open IPv4 Configuration page
    input_text    id=ip    192.168.1.1
    sleep    2
    input_text    id=mask    255.255.255.0
    sleep    2
    click element    id=lang_apply
    sleep    100
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    sleep    10

Open IPv4 Configuration page
    Open basic setup page
    click element    id=lang_submenu_basic_setting_lan
    sleep    2
    click element    id=lang_submenu_basic_setting_lan_lan4
    sleep    2
    wait_until_element_is_visible    id=mask    timeout=10

ip adddress and subnet mask config 192.168.0.1/255.255.0.0
    input_text    id=ip    192.168.0.1
    sleep    2
    input_text    id=mask    255.255.0.0
    sleep    2
    click element    id=lang_apply
    sleep    100

Verify LAN IP change to 192.168.0.0/16
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.0.
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=


ip adddress and subnet mask config 172.17.0.1/255.255.0.0
    input_text    id=ip    172.17.0.1
    sleep    2
    input_text    id=mask    255.255.0.0
    sleep    2
    click element    id=lang_apply
    sleep    100

Verify LAN IP change to 172.56.0.0/16
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    172.56.0.
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=

ip adddress and subnet mask config 10.0.0.1/255.0.0.0
    input_text    id=ip    10.0.0.1
    sleep    2
    input_text    id=mask    255.0.0.0
    sleep    2
    click element    id=lang_apply
    sleep    100

Verify LAN IP change to 10.0.0.0/8
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    10.0.0.
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=

Verify LAN IP change to 192.168.2.1/24
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.2.
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=


Reset settings 1
    run keyword and ignore error    Reset Default DUT
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    sleep    5

Change LAN IP to diffrent from default address
    input_text    id=ip    192.168.2.1
    sleep    2
    input_text    id=mask    255.255.255.0
    sleep    2
    click element    id=lang_apply
    sleep    100

Verify that LAN Side IP Address can be changed
    Run    sudo ifconfig eth3 192.168.2.51 netmask 255.255.255.0
    sleep    10
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.2.
    Open White label Web GUI    192.168.2.1
    sleep    5
    wait_until_element_is_visible    id=acnt_passwd    timeout=90
    input_text    id=acnt_passwd    ${DUT_Password}
    sleep    1
    click element    id=myButton
    sleep    5
    Wait until element is visible    id=lang_dev_info_name_title    timeout=30
    sleep    3
    ${get_lanIP}=    Fetch From Right  ${get_lanIP}    .
    Should Match Regexp    ${get_lanIP}    1[0-9][0-9]

Reset settings FN23LN001
    Run    sudo ifconfig eth3 192.168.0.51 netmask 255.255.0.0
    Login GUI    http://192.168.0.1/    ${DUT_Password}
    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser

Reset settings FN23LN002
    Run    sudo ifconfig eth3 172.17.0.51 netmask 255.255.0.0
    Login GUI    http://172.17.0.1/    ${DUT_Password}
    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser

Reset settings FN23LN003
    Run    sudo ifconfig eth3 10.0.0.51 netmask 255.0.0.0
    Login GUI    http://10.0.0.1/    ${DUT_Password}
    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser

Reset settings FN23LN004
    Run    sudo ifconfig eth3 192.168.2.51 netmask 255.255.255.0
    Login GUI    http://192.168.2.1/    ${DUT_Password}
    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser

Reset settings FN23LN005
    Run    sudo ifconfig eth3 192.168.1.6 netmask 255.255.255.248
    Login GUI    http://192.168.1.1/    ${DUT_Password}
    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser


Reset settings 2
    Open basic setup page
    click element    id=lang_submenu_basic_setting_lan
    sleep    2
    click element    id=lang_submenu_basic_setting_lan_lan4
    sleep    2
    wait_until_element_is_visible    id=mask    timeout=10
    input_text    id=ip    192.168.1.1
    sleep    2
    run keyword and ignore error    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    30
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    sleep    10
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    Close Browser

Change subnet mask(not default value) and then click apply button
    input_text    id=ip    192.168.1.1
    sleep    2
    input_text    id=mask    255.255.255.248
    sleep    2
    click element    id=lang_apply
    sleep    100
    Run    sudo ifconfig eth3 192.168.1.6 netmask 255.255.255.248

Verify the Subnet Mask should be 255.255.0.0
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${eth2_ifconfig}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface} | grep netmask    prompt=vagrant@lanhost    timeout=60
    ${get_mask}=    Fetch From Right  ${eth2_ifconfig}    netmask
    ${get_mask}=    Fetch From Left    ${get_mask}    broadcast
    ${get_mask}=    Strip String    ${get_mask}
    Should Contain     ${get_mask}    255.255.0.0

Check client can not get ip from DUT
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    run keyword and ignore error    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    run keyword and ignore error    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    Should Not Contain     ${get_lanIP}    192.168.1.

Set static IP for client and check the client can access WebGUI
    Close Browser
    Login GUI    ${URL}    ${DUT_Password}
    Open basic setup page
    click element    id=lang_submenu_basic_setting_lan
    sleep    2
    click element    id=lang_submenu_basic_setting_lan_lan4
    sleep    2
    wait_until_element_is_visible    id=mask    timeout=10
    click element    id=btn
    sleep    2
    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    2
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    run keyword and ignore error    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.1.
    Close Browser

Change DHCP server setting
    input_text    id=ip    192.168.123.1
    sleep    2
    input_text    id=dhcp_start_input    50
    sleep    2
    input_text    id=dhcp_end_input    75
    sleep    2
    input_text    id=dhcp_lease_input    180
    sleep    2
    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    2

Verify the DHCP related information
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.123
    ${get_lanIP}=    Fetch From Right  ${get_lanIP}    .
    Should Match Regexp    ${get_lanIP}    [5-7]{1}[0-9]{1}
    ${dns_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | cat /etc/resolv.conf    prompt=vagrant@lanhost    timeout=60
    Should Contain    ${dns_result}    192.168.123.1

Change DHCP server setting > DNS Relay
    Run    sudo ifconfig eth3 192.168.123.51 netmask 255.255.255.0
    sleep    10
    run keyword and ignore error    Close Browser
    sleep    2
    open browser    http://192.168.123.1/
    sleep    3
    wait_until_element_is_visible    id=acnt_passwd    timeout=90
    input_text    id=acnt_passwd    ${DUT_Password}
    sleep    1
    click element    id=myButton
    sleep    5
    Wait until element is visible    id=lang_dev_info_name_title    timeout=30
    sleep    3
    Open basic setup page
    click element    id=lang_submenu_basic_setting_lan
    sleep    2
    click element    id=lang_submenu_basic_setting_lan_lan4
    sleep    2
    wait_until_element_is_visible    id=mask    timeout=10
    click element    id=dns_relay
    sleep    2
    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    60

Verify the DHCP related information > DNS Relay
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${dns_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | cat /etc/resolv.conf    prompt=vagrant@lanhost    timeout=60
    Should Contain    ${dns_result}    192.168.123.1


Reset settings 3 > Default DUT
    Run    sudo ifconfig eth3 192.168.123.51 netmask 255.255.255.0
    run keyword and ignore error    Close Browser
    sleep    2
    open browser    http://192.168.123.1/
    sleep    3
    wait_until_element_is_visible    id=acnt_passwd    timeout=90
    input_text    id=acnt_passwd    ${DUT_Password}
    sleep    1
    click element    id=myButton
    sleep    5
    Wait until element is visible    id=lang_dev_info_name_title    timeout=30
    sleep    3
    run keyword and ignore error    Reset Default DUT
    sleep    5
    Run    sudo ifconfig eth3 192.168.1.51 netmask 255.255.255.0
    Close Browser

Verify DHCP IP Address Pool
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.1.
    ${get_lanIP}=    Fetch From Right  ${get_lanIP}    .
    Should Match Regexp    ${get_lanIP}    1[0-9][0-9]

Change DNS Servers to Specified IP Address
    click element    id=dns_manually
    sleep    2
    input_text    id=dns1    168.95.1.1
    sleep    2
    input_text    id=dns2    168.95.192.1
    sleep    2
    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    20

release/renew IP on LAN client
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15

Verify DNS Servers
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | ifconfig /all    prompt=vagrant@lanhost    timeout=60
    sleep    5
    #${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | nmcli dev show | grep 'IP4.DNS'    prompt=vagrant@lanhost    timeout=60
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | cat /etc/resolv.conf    prompt=vagrant@lanhost    timeout=60
    Should Contain    ${ping_result}    168.95.1.1
    sleep    2
    Should Contain    ${ping_result}    168.95.192.1


Verify DHCP Reservation "Add Clients" button
    run keyword and ignore error    click element    xpath=//*[@id="page_content_l1"]/form/div[7]/div/button
    sleep    2
    click element    xpath=//*[@id="dhcpreserved_add_btn"]
    sleep    2
    ${get_lanpc_mac}=    get MAC from host    lanhost
    input_text    id=dhcpreserved_mac    ${get_lanpc_mac}
    sleep    2
    input_text    id=dhcpreserved_ip    192.168.1.101
    sleep    2
    click element    xpath=//*[@id="dialog-frame"]/div/div[3]/div/button[2]
    sleep    3
    ${message}=    Get Text    xpath=//*[@id="lan_dhcpreserved_tbody"]/tr/td[2]/div
    Should Contain    ${message}    ${get_lanpc_mac}
    sleep    1
    ${message}=    Get Text    xpath=//*[@id="lan_dhcpreserved_tbody"]/tr/td[3]/div
    Should Contain    ${message}    192.168.1.101
    sleep    30
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=90
    sleep    15
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    Should Contain     ${get_lanIP}    192.168.1.101


Verify Clients Already Reserved
    click element    xpath=//*[@id="dhcpreserved_add_btn"]
    sleep    2

Delete Clients Already Reserved, verify client list is correct
    Login GUI    ${URL}    ${DUT_Password}
    Open LAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=edit_reserved_ip
    sleep    2
    click element    xpath=//*[@id="lan_dhcpreserved_tbody_id_0"]/td[4]/button[2]/img
    sleep    40
    Element Should Not Be Visible    xpath=//*[@id="lan_dhcpreserved_tbody_id_0"]/td[4]/button[2]/img
    Close Browser

Set IP Address Range is 192.168.1.100 to 102
    input_text    id=dhcp_end_input    102
    sleep    2
    click element    xpath=//*[@id="page_content_l1"]/form/div[8]/div/button[1]
    sleep    30


Add a Client to DHCP Reservation > show error message
    click element    xpath=//*[@id="page_content_l1"]/form/div[7]/div/button
    sleep    2
    click element    id=dhcpreserved_add_btn
    sleep    2
    ${get_lanpc_mac}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    ${get_lanpc_mac}=    Fetch From Right  ${get_lanpc_mac}    HWaddr
    ${get_lanpc_mac}=    Fetch From Left    ${get_lanpc_mac}    inet addr:
    ${get_lanpc_mac}=    Strip String    ${get_lanpc_mac}
    ${get_lanIP}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    @{get_lanIP}=    Get Regexp Matches    ${get_lanIP}    (\\d+\\.){3}\\d+
    ${get_lanIP}=    Strip String    ${get_lanIP}[0]
    input_text    id=dhcpreserved_mac    ${get_lanpc_mac}
    sleep    2
    input_text    id=dhcpreserved_ip    ${get_lanIP}
    sleep    2
    run keyword and ignore error    click element    xpath=//*[@id="dialog-frame"]/div/div[3]/div/button[2]/span
    sleep    2
    click element    id=dhcpreserved_add_btn
    sleep    10
    input_text    id=dhcpreserved_ip    ${get_lanIP}
    sleep    2
    input_text    id=dhcpreserved_mac    08:00:27:4E:47:9C
    sleep    2
    run keyword and ignore error    click element    xpath=//*[@id="dialog-frame"]/div/div[3]/div/button[2]/span
    sleep    2
    click_alert_ok_button
    run keyword and ignore error    click element    xpath=//*[@id="lan_dhcpreserved_tbody"]/tr/td[4]/a[1]
    sleep    2
    input_text    id=dhcpreserved_ip    192.168.1.103
    sleep    2
    run keyword and ignore error    click element    xpath=//*[@id="dialog-frame"]/div/div[3]/div/button[2]
    sleep    2
    click_alert_ok_button

Open management page
    click element    xpath=//*[@id="lang_mainmenu_management"]
    sleep    2
    wait_until_element_is_visible    id=lang_reboot_btn_title    timeout=5

Open basic setup page
    click element    id=lang_mainmenu_basic_setting
    sleep    2
    wait_until_element_is_visible    id=wan_mode    timeout=5

Open status page
    click element    id=lang_mainmenu_status
    sleep    2
    wait_until_element_is_visible    id=ipv4type1    timeout=5

Open White label Web GUI
    [Tags]   @AUTHOR=Frank_Hung
    [Arguments]    ${URL}
    sleep    4
    open browser    ${URL}
    sleep    3

Wizard-Setup
    Login GUI    ${URL}    ${DUT_Password}
    Click Element    id=next
    sleep    2
    input text    id=new_pwd    admin
    sleep    1
    input text    id=confirm_pwd    admin
    sleep    1
    Click Element    id=next
    sleep    1
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_enable_btn    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal'    click element    id=switch_layout_enable_btn
    sleep    2
    Click Element    id=next
    sleep    1
    Click Element    id=apply
    sleep    180
    Close Browser

Login and Reset Default DUT
    [Arguments]    ${URL}    ${DUT_Password}
    Wait Until Keyword Succeeds    3x    10s    retry Login and Reset Default DUT    ${URL}    ${DUT_Password}


retry Login and Reset Default DUT
    [Tags]    @AUTHOR=Frank_Hung
    [Arguments]    ${URL}    ${DUT_Password}
    IF    ${Platform}=='SPF12'
        sleep    1
    ELSE IF    ${Platform}=='SPF13'
        Run    echo "vagrant" | sudo -S chmod 777 /dev/ttyUSB0
        ${result}=    cli    DUT_serial_port    rm /opt/feature/GUI-QUICKSETUP-ENABLED && /etc/init.d/device-ui restart    prompt=root@
        sleep    1
        log    ${result}
    END
    Login GUI    ${URL}    ${DUT_Password}
    Reset Default DUT
    IF    ${Platform}=='SPF12'
        sleep    1
    ELSE IF    ${Platform}=='SPF13'
        Wizard-Setup
    END


Reset Default DUT
    [Tags]    @AUTHOR=Frank_Hung
    Go to Reset to Default Page
    Reset to Default DUT

Go to Reset to Default Page
    click element    id=menu_management
    sleep    2
    click element    id=menu_management_settings
    sleep    2


Reset to Default DUT
    click element    id=lang_restore_btn
    sleep    2
    click element    id=confirm_dialog_confirmed
    sleep    300
#    Run    python3 /home/vagrant/apc_script_power_off_to_on_port8.py
#    sleep    240
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} down
#    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} up
#    sleep    4
    Reload Page
    Wait until element is visible    id=acnt_passwd    timeout=60
    sleep    2
    close browser
    sleep    2
    Open Web GUI    ${URL}
    sleep    5
    input_text    id=acnt_passwd    ${DUT_Password}
    sleep    1
    close browser
