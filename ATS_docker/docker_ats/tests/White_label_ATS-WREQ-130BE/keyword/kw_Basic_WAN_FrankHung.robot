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



print debug message to console
    Run    echo "vagrant" | sudo -S chmod 777 /dev/ttyUSB0
    ${result}=    cli    DUT_serial_port    cat /etc/config/network    prompt=root@
    log    ${result}
    sleep    1
    ${result}=    cli    DUT_serial_port    cat /etc/config/wireless    prompt=root@
    log    ${result}
    sleep    1
    ${result}=    cli    DUT_serial_port    ps    prompt=root@
    log    ${result}
    sleep    1

Verify DEVICES INFORMATION is correct on GUI for STATIC Mode
    Login GUI    ${URL}    ${DUT_Password}
    ${result}=    Get Text    id=dashboard_internet_protocol
    Should Be Equal    ${result}    STATIC
    sleep    1
    ${result}=    Get Text    id=dashboard_internet_address
    Should Contain    ${result}    172.16.11.
    ${result}=    Get Text    id=dashboard_internet_dns1
    Should Contain Any    ${result}   168.95.1.1    10.5.161.254
    ${result}=    Get Text    id=dashboard_internet_macaddress
    Should Not Be Empty    ${result}
    Close Browser

Verify DEVICES INFORMATION is correct on GUI for PPPoE Mode
    Login GUI    ${URL}    ${DUT_Password}
    ${result}=    Get Text    id=dashboard_internet_protocol
    Should Be Equal    ${result}    PPPoE
    sleep    1
    ${result}=    Get Text    id=dashboard_internet_address
    Should Contain    ${result}    172.19.
    ${result}=    Get Text    id=dashboard_internet_dns1
    Should Contain Any    ${result}   168.95.1.1    10.5.161.254
    ${result}=    Get Text    id=dashboard_internet_macaddress
    Should Not Be Empty    ${result}
    Close Browser

Verify Default WAN Mode is DHCP
    wait until keyword succeeds    6x    5s    Verify DEVICES INFORMATION is correct on GUI for DHCP Mode

Verify DEVICES INFORMATION is correct on GUI for DHCP Mode
    Login GUI    ${URL}    ${DUT_Password}
    ${result}=    Get Text    id=dashboard_internet_protocol
    Should Be Equal    ${result}    DHCP
    sleep    1
    ${result}=    Get Text    id=dashboard_internet_address
    Should Contain    ${result}    172.16.
    ${result}=    Get Text    id=dashboard_internet_dns1
    Should Contain Any    ${result}   168.95.1.1    10.5.161.254
    ${result}=    Get Text    id=dashboard_internet_macaddress
    Should Not Be Empty    ${result}
    Close Browser

Verify LAN PC can stend traffic to WAN PC
    WAN PC Open iperf3 for Listen
    LAN PC Send Traffic to WAN PC by iperf3


WAN PC Open iperf3 for Listen
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S killall iperf3
    sleep    2
    ${result}=    Telnet.Execute Command    iperf3 -s&
    log    ${result}

LAN PC Send Traffic to WAN PC by iperf3
    ${wanhost_IP}=    Get IP from host    wanhost
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.lanhost.ip}    timeout=60    prompt=${DEVICES.lanhost.prompt}     port=${DEVICES.lanhost.port}
    Telnet.Login    ${DEVICES.lanhost.user_name}    ${DEVICES.lanhost.password}    login_prompt=${DEVICES.lanhost.login_prompt}    password_prompt=${DEVICES.lanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.lanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    iperf3 -c ${wanhost_IP} -t 10 -P 4 -i 1
    log    ${result}
    Should Contain    ${result}    Mbits/sec
    Should Contain    ${result}    connected


Verify LAN PC can ping to 8.8.8.8
    wait until keyword succeeds    6x    5s    retry Verify LAN PC can ping to 8.8.8.8


retry Verify LAN PC can ping to 8.8.8.8
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    sleep    1
    Should Contain     ${ping_result}    ttl=

Verify LAN PC unable to ping 8.8.8.8 and 168.95.1.1
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    sleep    15
    ${ping_result}=    cli   lanhost    ping 192.168.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    sleep    1
    Should Not Contain     ${ping_result}    ttl=
    ${ping_result}=    cli   lanhost    cat /etc/resolv.conf    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    ping 168.95.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Not Contain     ${ping_result}    ttl=



Disable NAT on DUT
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_nat    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal checked'    click element    id=switch_layout_nat
    sleep    2
    click element    id=apply
    sleep    120
    Close Browser

Clear cisco port
    [Documentation]  Clear cisco port to prevent  Connection refused
    [Arguments]    ${cisco_line}
    Telnet.Open Connection    ${DEVICES.terminal_server.ip}    timeout=60    prompt=${DEVICES.terminal_server.prompt}     port=${DEVICES.terminal_server.port}
    Telnet.Login    ${DEVICES.terminal_server.user_name}    ${DEVICES.terminal_server.password}    login_prompt=${DEVICES.terminal_server.login_prompt}    password_prompt=${DEVICES.terminal_server.password_prompt}
    Telnet.Set Timeout    ${DEVICES.terminal_server.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    ATS-TERMSERV#
    ${result}=    Telnet.Execute Command    lab
    log    ${result}
    Telnet.Set Prompt    [confirm]
    ${result}=    Telnet.Execute Command    clear line ${cisco_line}
    log    ${result}
    Telnet.Set Prompt    ATS-TERMSERV#
    ${result}=    Telnet.Execute Command    y
    log    ${result}
    Telnet.Set Prompt    ATS-TERMSERV#
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Clear Cisco Router Port
    [Tags]   @AUTHOR=Frank_Hung
    [Arguments]    ${Port_Number_Clear}
    Run keyword and ignore error   wait until keyword succeeds    2x    3s    Clear cisco port    ${Port_Number_Clear}

Check if LAN PC can get IPv6 address and can access IPv6 WAN host
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "global"
    log    ${result}
    Should Contain    ${result}    2001:5:
    ${result}=    cli    lanhost    ping6 2001:1234:5678:9abc::1 -c 4
    Should Contain    ${result}    ttl=

Verify DUT WAN v6 IP should be changed
    [Arguments]    ${IP}
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep    3
    ${DUT_v6_IP}=    Get Text    id=ipaddress_diag
    Should not Contain    ${DUT_v6_IP}    ${IP}

v6 Server setup, send out Router Advertisement
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    ipv6 unicast-routing
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, NOT send out Router Advertisement
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    no ipv6 unicast-routing
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Check the IPv6 address in LAN PC,make sure LAN PC can get IP address, verify LAN PC can ping v6 server IP
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "global"
    log    ${result}
    Should Contain    ${result}    2001:5:
    ${result}=    cli    lanhost    ping6 2001:1234:5678:9abc::1 -c 4
    Should Contain    ${result}    ttl=

verify that Router sends out dhcp solicitation (IA_NA option) after it detects the M bit sets to 1 in RA message
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Router Advertisement
    Should Contain    ${capture_result}    Solicit

Verify Router recognizes the M bit in RA message and requesting dhcp server for IPv6 address instead
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Identity Association for Non-temporary Address
    Should Contain    ${capture_result}    IA Address

Sniffer PC start capture packet for FN23WN023
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6.type==134||dhcpv6" -a duration:150 > tshark_file&
    log    ${result}


Sniffer PC start capture packet for FN23WN023-2
    Telnet.Close All Connections
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    rm /home/vagrant/tshark_file
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y dhcpv6 -V -a duration:150 > tshark_file&
    log    ${result}



Verify Router will send out "Dhcp Decline" message back to the dhcp server
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Decline

Sniffer PC down up interface
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S ifconfig ${DEVICES.wanhost.interface} down
    sleep    4
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S ifconfig ${DEVICES.wanhost.interface} up
    sleep    15

Get DUT v6 IP Address, assign it to Sniffer PC for SLAAC
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    sleep    2
    ${DUT_v6_IP}=    Get Text    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[3]
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S ifconfig ${DEVICES.wanhost.interface} inet6 add ${DUT_v6_IP}/64
    Close Browser
    [return]    ${DUT_v6_IP}

Get DUT v6 IP Address, assign it to Sniffer PC
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    sleep    2
    ${DUT_v6_IP}=    Get Text    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[3]
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S ifconfig ${DEVICES.wanhost.interface} inet6 add ${DUT_v6_IP}/128
    Close Browser
    [return]    ${DUT_v6_IP}

Sniffer PC start capture packet for FN23WN022
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y dhcpv6 -a duration:150 > tshark_file&
    log    ${result}


Verify from sniffer capture that Router sends out "dhcp release" message
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Release

Sniffer PC start capture packet for FN23WN021
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y dhcpv6 -a duration:150 > tshark_file&
    log    ${result}


Verify Router needs to send a dhcp information request message to dhcp server, dhcp server replies with the configuration informations that Router requested
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Solicit
    Should Contain    ${capture_result}    Advertise
    Should Contain    ${capture_result}    Request
    Should Contain    ${capture_result}    Reply


Sniffer PC start capture packet for FN23WN020
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y dhcpv6 -a duration:150 > tshark_file&
    log    ${result}


Verify the interface identifier of global unicast address conforms to EUI-64 format
    [Arguments]    ${MAC}
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file | grep Request
    Log    ${capture_result}
    Should Contain    ${capture_result}    ${MAC}




Sniffer PC start capture packet for FN23WN018
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y dhcpv6 -a duration:150 > tshark_file&
    log    ${result}



Sniffer PC start capture packet for FN23WN017
    [Arguments]    ${Linklocal_IP}
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6&&ipv6.src==${Linklocal_IP}" -a duration:150 -V > tshark_file&
    log    ${result}


Verify the frame type in link layer is ether type of value 86DD
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    Type: IPv6 (0x86dd)

Verify Accept valid Router Advertisement message from its neighboring router and configure itself with global unicast address plus default route
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file | grep "Router Advertisement from"
    Log    ${capture_result}
    Should Contain    ${capture_result}    Router Advertisement from

Verify Router sends out MLD report message to join solicited-node multicast address
    [Arguments]    ${Linklocal_IP}
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file | grep "Multicast Listener Report Message v2"
    Log    ${capture_result}
    Should Contain    ${capture_result}    ${Linklocal_IP}

Sniffer PC start capture packet for FN23WN015
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6.type==133||icmpv6.type==134||icmpv6.type==135||icmpv6.type==143" -a duration:300 > tshark_file&
    log    ${result}

Sniffer PC start capture packet for FN23WN014
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    log    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6.type==133||icmpv6.type==135" -a duration:150 > tshark_file&
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6.type==133||icmpv6.type==135" -a duration:150 > tshark_file&
    log    ${result}

verify The source address used in the subsequent Router Solicitation MUST be the link-local address on the WAN interface
    [Arguments]    ${Linklocal_IP}
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file | grep "Router Solicitation"
    Log    ${capture_result}
    Should Contain    ${capture_result}    ${Linklocal_IP}

Verify Router performs DAD procedure (Neighbor Solicitation) before assigning the link local address to its interface
    [Arguments]    ${Linklocal_IP}
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    ICMPv6 86 Neighbor Solicitation for ${Linklocal_IP}

Verify Router wan interface can generate its own link local address
    [Arguments]    ${Linklocal_IP}
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   cat tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    ICMPv6 86 Neighbor Solicitation for ${Linklocal_IP}

Sniffer PC start capture packet
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmpv6.type==133||icmpv6.type==135" -a duration:150 > tshark_file&
    log    ${result}


Verify on GUI, IP address : "EUI-64", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    [Arguments]    ${MAC}
    Wait Until Keyword Succeeds    4x    2s    retry Verify on GUI, IP address : "EUI-64", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"    ${MAC}

retry Verify on GUI, IP address : "EUI-64", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    [Arguments]    ${MAC}
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep    3
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:
    Should Contain    ${result}    ${MAC}
#    ${result}=    Get Text    id=pd_diag
#    Should Not Contain    ${result}    2001:5:
#    Should Be Empty    ${result}
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=prefix_diag
    Should Contain    ${result}    64
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    sleep    2
    Close Browser


GUI setup, Get IPv6 Address:SLAAC, PD Disable
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    click element    id=lang_ipv6_slaac
    sleep    1
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_PD    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal checked'    click element    id=switch_layout_PD
    sleep    2
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Verify LAN PC get v6 IP Link-local: M bit 0, O bit 1
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "inet6"
    log    ${result}
    Should Not Contain    ${result}    2001:5:
    Should Contain    ${result}    fe80:

Verify LAN PC get v6 IP Link-local: M bit 1, O bit 1, Disable PD
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "inet6"
    log    ${result}
    Should Not Contain    ${result}    2001:5:
    Should Contain    ${result}    fe80:

Verify LAN PC get v6 IP from v6 Server: M bit 0, O bit 1
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "global"
    log    ${result}
    Should Contain    ${result}    2001:5:



Verify LAN PC get v6 IP from v6 Server: M bit 1, O bit 1
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down
    sleep    4
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    40
    ${result}=    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} | grep "global"
    log    ${result}
    Should Contain    ${result}    2001:5:

Verify on GUI, IP address : "EUI-64", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    [Arguments]    ${ipv6_DUT_MAC}
    Wait Until Keyword Succeeds    3x    2s    retry Verify on GUI, IP address : "EUI-64", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"    ${ipv6_DUT_MAC}





retry Verify on GUI, IP address : "EUI-64", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    [Arguments]    ${MAC}
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep    3
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:
    Should Contain    ${result}    ${MAC}
#    ${result}=    Get Text    id=pd_diag
#    Should Contain    ${result}    2001:5:
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=prefix_diag
    Should Contain    ${result}    64
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    sleep    2
    Close Browser

Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    Wait Until Keyword Succeeds    3x    2s    retry Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"


retry Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : Null, Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep    3
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:
#    ${result}=    Get Text    id=pd_diag
#    Should Not Contain    ${result}    2001:5:
#    Should Be Empty    ${result}
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=prefix_diag
    Should Contain Any    ${result}    128    64
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    sleep    2
    Close Browser

Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    Wait Until Keyword Succeeds    3x    2s    retry Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"


retry Verify on GUI, IP address : "get ip from RA(pd) ipv6 server", Prefix Delegation : "get Prefix from ipv6 server", Default Gate way: "get from ipv6 server", Primary DNS: "get from ipv6 server"
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Status GUI
    click element    xpath=//*[@id="status_wan_ipv6_table_id_0"]/td[5]/button/img
    sleep    3
    ${result}=    Get Text    id=ipaddress_diag
    Should Contain    ${result}    2001:1234:
#    ${result}=    Get Text    id=pd_diag
#    Should Contain    ${result}    2001:5:
    ${result}=    Get Text    id=gateway_diag
    Should Contain    ${result}    fe80::
    ${result}=    Get Text    id=dns1_diag
    Should Contain    ${result}    2001:4860:4860::8888
    ${result}=    Get Text    id=prefix_diag
    Should Contain Any   ${result}    128    64
    ${result}=    Get Text    id=status_diag
    Should Contain    ${result}    Connected
    sleep    2
    Close Browser

GUI setup, Get IPv6 Address:SLAAC, PD enable
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=lang_ipv6_slaac
    sleep    1
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_PD    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal'    click element    id=switch_layout_PD
    sleep    2
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Verify Internet Status is UP on GUI
    Login GUI    ${URL}    ${DUT_Password}
    ${result}=    Get Text    id=internet_downup_status
    Should Be Equal    ${result}    Up
    sleep    2
    Close Browser

GUI setup, Get IPv6 Address:DHCPv6, PD Disable
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=lang_ipv6_dhcpv6
    sleep    1
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_PD    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal checked'    click element    id=switch_layout_PD
    sleep    2
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

GUI setup, Get IPv6 Address:DHCPv6, PD enable
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    click element    id=lang_dhcp
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=lang_ipv6_dhcpv6
    sleep    1
    ${enable_or_disable}=    get_element_attribute    id=switch_layout_PD    class
    log    ${enable_or_disable}
    sleep    2
    Run Keyword If      '${enable_or_disable}'=='switch hidden-dom-removal'    click element    id=switch_layout_PD
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

v6 Server setup, remove the IA_NA in DHCPv6 setting
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    ipv6 dhcp pool F_DHCP_POOL
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    no address prefix 2001:1234:5678:9ABC::/64 lifetime 18000 9000
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, add the IA_NA in DHCPv6 setting
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    ipv6 dhcp pool F_DHCP_POOL
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    address prefix 2001:1234:5678:9ABC::/64 lifetime 18000 9000
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2


v6 Server setup, DHCPv6 Prefix Enable
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    ipv6 dhcp pool F_DHCP_POOL
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    prefix-delegation pool dhcpv6-pool1
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, DHCPv6 Prefix Disable
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    ipv6 dhcp pool F_DHCP_POOL
    log    ${result}
    Telnet.Set Prompt    C1801(config-dhcpv6)#
    ${result}=    Telnet.Execute Command    no prefix-delegation pool dhcpv6-pool1
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, O bit 1
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    interface GigabitEthernet0/0
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    ipv6 nd other-config-flag
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, O bit 0
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    interface GigabitEthernet0/0
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    no ipv6 nd other-config-flag
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Reboot Cisco Router and waiting 180 seconds
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    System configuration has been modified. Save? [yes/no]:
    ${result}=    Telnet.Execute Command    reload
    log    ${result}
    Telnet.Set Prompt        Proceed with reload? [confirm]
    ${result}=    Telnet.Execute Command    no
    log    ${result}
    Telnet.Set Timeout    80
    Telnet.Set Prompt    System Bootstrap
    ${result}=    Telnet.Execute Command    yes
    Telnet.Close All Connections
    sleep    240

v6 Server setup, M bit 1
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    interface GigabitEthernet0/0
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    ipv6 nd managed-config-flag
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

v6 Server setup, M bit 0
    Telnet.Open Connection    ${DEVICES.ciscoRouter.ip}    timeout=60    prompt=${DEVICES.ciscoRouter.prompt}     port=${DEVICES.ciscoRouter.port}
    Telnet.Login    ${DEVICES.ciscoRouter.user_name}    ${DEVICES.ciscoRouter.password}    login_prompt=${DEVICES.ciscoRouter.login_prompt}    password_prompt=${DEVICES.ciscoRouter.password_prompt}
    Telnet.Set Timeout    ${DEVICES.ciscoRouter.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    C1801>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    Password:
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    cisco1234567890
    log    ${result}
    Telnet.Set Prompt    C1801(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    interface GigabitEthernet0/0
    log    ${result}
    Telnet.Set Prompt    C1801(config-if)#
    ${result}=    Telnet.Execute Command    no ipv6 nd managed-config-flag
    log    ${result}
    Telnet.Set Prompt    C1801#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Start capture PADT packets from WAN side
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "pppoed" > /home/vagrant/tshark_file&
    log    ${result}


Check there are PADT packets in WAN side about 11 minutes
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    cli    wanhost    \n    prompt=vagrant@    timeout=10
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    cat /home/vagrant/tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    PADT
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    rm /home/gemtek/tshark_file

Down WAN Interface
    Telnet.Open Connection    ${DEVICES.cisco_LAN_Switch.ip}    timeout=60    prompt=${DEVICES.cisco_LAN_Switch.prompt}     port=${DEVICES.cisco_LAN_Switch.port}
    Telnet.Login    ${DEVICES.cisco_LAN_Switch.user_name}    ${DEVICES.cisco_LAN_Switch.password}    login_prompt=${DEVICES.cisco_LAN_Switch.login_prompt}    password_prompt=${DEVICES.cisco_LAN_Switch.password_prompt}
    Telnet.Set Timeout    ${DEVICES.cisco_LAN_Switch.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    LAN-SW>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    interface ${DUT_WAN_Interface_on_cisco_switch}
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    shutdown
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Up WAN Interface
    Telnet.Open Connection    ${DEVICES.cisco_LAN_Switch.ip}    timeout=60    prompt=${DEVICES.cisco_LAN_Switch.prompt}     port=${DEVICES.cisco_LAN_Switch.port}
    Telnet.Login    ${DEVICES.cisco_LAN_Switch.user_name}    ${DEVICES.cisco_LAN_Switch.password}    login_prompt=${DEVICES.cisco_LAN_Switch.login_prompt}    password_prompt=${DEVICES.cisco_LAN_Switch.password_prompt}
    Telnet.Set Timeout    ${DEVICES.cisco_LAN_Switch.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    LAN-SW>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    interface ${DUT_WAN_Interface_on_cisco_switch}
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    no shutdown
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2


Down Agent Interface
    Telnet.Open Connection    ${DEVICES.cisco_LAN_Switch.ip}    timeout=60    prompt=${DEVICES.cisco_LAN_Switch.prompt}     port=${DEVICES.cisco_LAN_Switch.port}
    Telnet.Login    ${DEVICES.cisco_LAN_Switch.user_name}    ${DEVICES.cisco_LAN_Switch.password}    login_prompt=${DEVICES.cisco_LAN_Switch.login_prompt}    password_prompt=${DEVICES.cisco_LAN_Switch.password_prompt}
    Telnet.Set Timeout    ${DEVICES.cisco_LAN_Switch.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    LAN-SW>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    interface ${Agent_Interface_on_cisco_switch}
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    shutdown
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2

Up Agent Interface
    Telnet.Open Connection    ${DEVICES.cisco_LAN_Switch.ip}    timeout=60    prompt=${DEVICES.cisco_LAN_Switch.prompt}     port=${DEVICES.cisco_LAN_Switch.port}
    Telnet.Login    ${DEVICES.cisco_LAN_Switch.user_name}    ${DEVICES.cisco_LAN_Switch.password}    login_prompt=${DEVICES.cisco_LAN_Switch.login_prompt}    password_prompt=${DEVICES.cisco_LAN_Switch.password_prompt}
    Telnet.Set Timeout    ${DEVICES.cisco_LAN_Switch.timeout}
    ${result}=    Telnet.Read
    sleep    2
    Telnet.Set Prompt    LAN-SW>
    ${result}=    Telnet.Execute Command    \r
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    enable
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config)#
    ${result}=    Telnet.Execute Command    config t
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    interface ${Agent_Interface_on_cisco_switch}
    log    ${result}
    Telnet.Set Prompt    LAN-SW(config-if)#
    ${result}=    Telnet.Execute Command    no shutdown
    log    ${result}
    Telnet.Set Prompt    LAN-SW#
    ${result}=    Telnet.Execute Command    end
    log    ${result}
    Telnet.Set Prompt    Press RETURN to get started
    ${result}=    Telnet.Execute Command    exit
    log    ${result}
    Telnet.Close All Connections
    sleep    2



Up LAN PC and ATS Server Network Interface
    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} up
    sleep    2
    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} up
    sleep    2

Down ATS Server Interface
    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} down
    sleep    2


Down LAN PC Network Interface
    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S ifconfig ${DEVICES.lanhost.interface} down

Check the PPPoE IP Address from GUI and other information are correct
    Login GUI    ${URL}    ${DUT_Password}
    ${result}=    Get Text    id=dashboard_internet_address
    Should Contain    ${result}    172.19.
    ${result}=    Get Text    id=dashboard_internet_protocol
    Should Contain    ${result}    PPPoE

WAN PC check the ICMP packet has been Fragment (MTU is 1300)
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    cli    wanhost    \n    prompt=vagrant@WAN-host    timeout=10
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    cat /home/vagrant/tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    [2 IPv4 Fragments (1408 bytes)
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    rm /home/vagrant/tshark_file

WAN PC check the ICMP packet has been Fragment (MTU is 1492)
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    cli    wanhost    \n    prompt=vagrant@WAN-host    timeout=10
    cli    wanhost    \n    prompt=vagrant@WAN-host    timeout=10
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    cat /home/vagrant/tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    [2 IPv4 Fragments (1508 bytes)
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    rm /home/vagrant/tshark_file

WAN PC check the ICMP packet has been Fragment (MTU is 1400)
    Wait Until Keyword Succeeds    4x    2s    cli   wanhost    echo '${DEVICES.wanhost.password}' | sudo -S killall tshark
    sleep    5
    cli    wanhost    \n    prompt=vagrant@WAN-host    timeout=10
    cli    wanhost    \n    prompt=vagrant@WAN-host    timeout=10
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    cat /home/vagrant/tshark_file
    Log    ${capture_result}
    Should Contain    ${capture_result}    [2 IPv4 Fragments (1458 bytes)
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost    rm /home/vagrant/tshark_file

Setup WAN mode to Static IP mode, incorrect IP in DNS1 and correct IP in DNS2
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to Static IP, incorrect IP in DNS1 and correct IP in DNS2

Setup WAN mode to Static IP mode, correct IP in DNS1 and incorrect IP in DNS2
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to Static IP, correct IP in DNS1 and incorrect IP in DNS2

Config WAN to Static IP, incorrect IP in DNS1 and correct IP in DNS2
    click element    id=lang_static
    sleep    1
    input_text    id=static_ip    172.16.11.20
    sleep    1
    input_text    id=static_mask    255.255.255.0
    sleep    1
    input_text    id=static_gatway    172.16.11.1
    sleep    1
    input_text    id=static_dns1    1.2.3.4
    sleep    1
    input_text    id=static_dns2    8.8.8.8
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    150
    Close Browser


Config WAN to Static IP, correct IP in DNS1 and incorrect IP in DNS2
    click element    id=lang_static
    sleep    1
    input_text    id=static_ip    172.16.11.20
    sleep    1
    input_text    id=static_mask    255.255.255.0
    sleep    1
    input_text    id=static_gatway    172.16.11.1
    sleep    1
    input_text    id=static_dns1    8.8.8.8
    sleep    1
    input_text    id=static_dns2    1.2.3.4
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    150
    Close Browser

Setup WAN mode to Static IP mode
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to Static IP

Config WAN to Static IP
    click element    id=lang_static
    sleep    1
    input_text    id=static_ip    172.16.11.20
    sleep    1
    input_text    id=static_mask    255.255.255.0
    sleep    1
    input_text    id=static_gatway    172.16.11.1
    sleep    1
    input_text    id=static_dns1    168.95.1.1
    sleep    1
    input_text    id=static_dns2    8.8.8.8
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Power OFF than Power ON DUT
    Run    python3 /home/vagrant/apc_script_power_off_to_on_port8.py

Waiting 180 seconds
    sleep    240

Waiting 240 seconds
    sleep    240
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} down
#    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} up
#    sleep    4


Waiting 10 seconds for log to Console
    sleep    10
    log to console    sleeping 10 seeconds

# (Open Web GUI provided by keyword/kw_gui_setup.robot)

LAN PC Renew IP
    Wait Until Keyword Succeeds    3x    2s    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S route del default    prompt=vagrant@lanhost
    sleep    3
    Wait Until Keyword Succeeds    3x    2s    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S route del default    prompt=vagrant@lanhost
    sleep    3
    Wait Until Keyword Succeeds    3x    2s    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S route del default    prompt=vagrant@lanhost
    sleep    3
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost   echo '${DEVICES.lanhost.password}' | sudo -S sudo dhclient ${DEVICES.lanhost.interface} -r
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost   echo '${DEVICES.lanhost.password}' | sudo -S sudo dhclient ${DEVICES.lanhost.interface}&
    sleep    10
    cli    lanhost    echo '${DEVICES.lanhost.password}' | sudo -S echo nameserver 8.8.8.8 > /etc/resolv.conf    prompt=vagrant@lanhost
    sleep    2

LAN PC Renew IP for Verify FN23WN007
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost   echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost   echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}&    prompt=vagrant@lanhost    timeout=60
    sleep    10

WAN PC Renew IP
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   echo '${DEVICES.wanhost.password}' | sudo -S dhclient ${DEVICES.wanhost.interface} -r    prompt=vagrant@WAN-host    timeout=60
    sleep    4
    Wait Until Keyword Succeeds    3x    2s    cli   wanhost   echo '${DEVICES.wanhost.password}' | sudo -S dhclient ${DEVICES.wanhost.interface}&    prompt=vagrant@WAN-host    timeout=60
    sleep    10
    ${result}=    cli   wanhost   ifconfig ${DEVICES.wanhost.interface}    prompt=vagrant@WAN-host    timeout=60
    log    ${result}
    Should Contain    ${result}    172.16.11.4

LAN PC ping WAN PC, using command "ping WAN PC IP -s 1400 -c 2"
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    2
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    sleep    4
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    ping 172.16.11.1 -s 1400 -c 2
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    ping 172.16.11.4 -s 1400 -c 2
    sleep    20

LAN PC ping WAN PC, using command "ping WAN PC IP -s 1500 -c 2"
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    2
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    sleep    4
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    ping 172.16.11.1 -s 1500 -c 2
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    ping 172.16.11.4 -s 1500 -c 2
    sleep    20

LAN PC ping WAN PC, using command "ping WAN PC IP -s 1450 -c 2"
    LAN PC Renew IP
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    ping 172.16.11.4 -s 1450 -c 4
    sleep    20

LAN PC Start capture packet
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.lanhost.ip}    timeout=60    prompt=${DEVICES.lanhost.prompt}     port=${DEVICES.lanhost.port}
    Telnet.Login    ${DEVICES.lanhost.user_name}    ${DEVICES.lanhost.password}    login_prompt=${DEVICES.lanhost.login_prompt}    password_prompt=${DEVICES.lanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.lanhost.timeout}
    ${result}=    Telnet.Read
    Telnet.Set Prompt    vagrant@
    ${result}=    Telnet.Execute Command    echo '${DEVICES.lanhost.password}' | sudo -S tshark -i ${DEVICES.lanhost.interface} -Y "ip.src==172.16.11.1" -a duration:180 > /home/vagrant/tshark_file&
    log    ${result}


WAN PC Start capture packet
    Wait Until Keyword Succeeds    3x    2s    WAN PC Renew IP
    Telnet.Close All Connections
    Telnet.Open Connection    ${DEVICES.wanhost.ip}    timeout=60    prompt=${DEVICES.wanhost.prompt}     port=${DEVICES.wanhost.port}
    Telnet.Login    ${DEVICES.wanhost.user_name}    ${DEVICES.wanhost.password}    login_prompt=${DEVICES.wanhost.login_prompt}    password_prompt=${DEVICES.wanhost.password_prompt}
    Telnet.Set Timeout    ${DEVICES.wanhost.timeout}
    ${result}=    Telnet.Read

    Telnet.Set Prompt    vagrant@WAN-host
    log    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmp.type==8" -V > /home/vagrant/tshark_file&
    ${result}=    Telnet.Execute Command    echo '${DEVICES.wanhost.password}' | sudo -S tshark -i ${DEVICES.wanhost.interface_Monitor} -Y "icmp.type==8" -V > /home/vagrant/tshark_file&
    log    ${result}


Verify there is no DHCP packet sent from WAN
    Wait Until Keyword Succeeds    4x    2s    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S killall tshark
    sleep    5
    cli    lanhost    \n    prompt=vagrant@lanhost    timeout=10
    cli    lanhost    \n    prompt=vagrant@lanhost    timeout=10
    ${capture_result}=    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    cat /home/vagrant/tshark_file
    Log    ${capture_result}
    Should Not Contain    ${capture_result}    DHCP
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost    rm /home/vagrant/tshark_file
    Wait Until Keyword Succeeds    3x    2s    cli   lanhost   echo '${DEVICES.lanhost.password}' | sudo -S killall dhclient&    prompt=vagrant@lanhost    timeout=60

Setup WAN mode to PPPoE mode with incorrect password
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to PPPoE mode with incorrect password

Setup WAN mode to PPPoE mode with incorrect user name
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to PPPoE mode with incorrect user name

Setup WAN mode to PPPoE mode
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to PPPoE mode

Setup WAN mode to PPPoE mode, MTU Size:1300
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to PPPoE mode, MTU Size:1300

Setup WAN mode to PPPoE mode, Dial Mode: Manual
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    Select From List By Value    id=wan_dial    manual_connect
    sleep    1
    input_text    id=mtu    1492
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    150
    Close Browser

Setup WAN mode to PPPoE mode, MTU(Default):Auto, Size:1492, Dial Mode: on Demand
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    Select From List By Value    id=wan_dial    dial_on_demand
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    input_text    id=dial_timeout    10
    sleep    1
    input_text    id=mtu    1492
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    150
    Close Browser

Setup WAN mode to PPPoE mode, MTU(Default):Auto, Size:1492
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to PPPoE mode, MTU Size:1492

Config WAN to PPPoE mode, MTU Size:1300
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    Select From List By Value    id=wan_dial    automatically
    sleep    1
    input_text    id=mtu    1300
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Config WAN to PPPoE mode, MTU Size:1492
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    input_text    id=mtu    1492
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Config WAN to PPPoE mode with incorrect password
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco_xxx
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Config WAN to PPPoE mode with incorrect user name
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco_xxx
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Config WAN to PPPoE mode
    click element    id=lang_ppp
    sleep    1
    input_text    id=ppp_name    cisco
    sleep    1
    input_text    id=ppp_pwd    cisco
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=btn_apply
    sleep    120
    Close Browser

Setup WAN mode to DHCP mode, MTU be "Manual", enter size be 1400
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to DHCP mode, MTU to 1400


Setup WAN mode to DHCP mode
    Login GUI    ${URL}    ${DUT_Password}
    Open WAN Page
    Config WAN to DHCP mode

Open WAN Status GUI
    click element    id=menu_status
    sleep    2
    click element    id=menu_status_wan
    sleep    2


Open WAN Page
    click element    id=lang_mainmenu_basic_setting
    sleep    2
    click element    id=menu_basic_setting_wan
    sleep    2
    Wait until element is visible    id=lang_dhcp
    sleep    1

Config WAN to DHCP mode, MTU to 1400
    click element    id=lang_dhcp
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    1
    input_text    id=mtu    1400
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    120
    Close Browser

Config WAN to DHCP mode
    click element    id=lang_dhcp
    sleep    1
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    sleep    2
    click element    id=apply
    sleep    240
    Close Browser

Verify LAN PC can access buffalo.jp
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    sleep    15
    ${ping_result}=    cli   lanhost    ping 192.168.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    ifconfig    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    cat /etc/resolv.conf    prompt=vagrant@lanhost    timeout=60
    sleep    1
    ${ping_result}=    cli   lanhost    ping buffalo.jp -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=

Verify LAN PC cannot access Internet
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${ping_result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}    prompt=vagrant@lanhost    timeout=60
    sleep    15
    ${ping_result}=    cli   lanhost    ping 192.168.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Not Contain     ${ping_result}    ttl=
    ${ping_result}=    cli   lanhost    ping 168.95.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Not Contain     ${ping_result}    ttl=

Verify LAN PC can access Internet
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface} -r&    prompt=vagrant@lanhost    timeout=60
    sleep    4
    ${result}=    cli   lanhost    echo '${DEVICES.lanhost.password}' | sudo -S dhclient ${DEVICES.lanhost.interface}&    prompt=vagrant@lanhost    timeout=60
    sleep    15
    ${result}=    cli   lanhost    ifconfig ${DEVICES.lanhost.interface}&    prompt=vagrant@lanhost    timeout=60
    log    ${result}
    ${ping_result}=    cli   lanhost    ping 192.168.1.1 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${ping_result}=    cli   lanhost    ping 8.8.8.8 -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${ping_result}=    cli   lanhost    ping www.google.com -c 4    prompt=vagrant@lanhost    timeout=60
    Should Contain     ${ping_result}    ttl=
    ${result}=     cli   lanhost    wget https://www.google.com    prompt=vagrant@lanhost    timeout=60
    Should Contain    ${result}    response... 200 OK

# (GUI helpers centralized in keyword/kw_gui_setup.robot)

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
    click element    id=lang_mainmenu_management
    sleep   2
    click element    id=lang_submenu_management_settings
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

Reset to Default DUT with setting password after login GUI
    Wait until element is visible    xpath=//*[@class="col-xs-12"]/button
    sleep    1
    click element    xpath=//*[@class="col-xs-12"]/button
    sleep    2
    Handle Alert    ACCEPT
    sleep    300
#    Run    python3 /home/vagrant/apc_script_power_off_to_on_port8.py
#    sleep    240
    close browser
    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} down
#    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} up
#    sleep    4
    Open Web GUI    ${URL}
#------Login GUI if detect login button
    sleep    5
    input_text    id=acnt_passwd    ${DUT_Password}
    sleep    1
    click element    id=myButton
    sleep    5
    Wait until element is visible    id=qs_pw
    input_text    id=qs_pw    admin
    sleep    1
    click element    xpath=//*[@class="dialog-footer"]/button
    sleep    240
#    Run    python3 /home/vagrant/apc_script_power_off_to_on_port8.py
#    sleep    240
    Wait until element is visible    id=acnt_passwd
    close browser



Reset to Default DUT with setting password
    Wait until element is visible    xpath=//*[@class="col-xs-12"]/button
    sleep    1
    click element    xpath=//*[@class="col-xs-12"]/button
    sleep    2
    Handle Alert    ACCEPT
    sleep    300
    close browser
    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} down
#    sleep    2
#    Run    echo 'vagrant' | sudo -S ifconfig ${ATS_to_DUT_Interface} up
#    sleep    4
    Open Web GUI    ${URL}
#------Login GUI if detect login button
    sleep    5
    Wait until element is visible    id=qs_pw
    input_text    id=qs_pw    admin
    sleep    1
    click element    xpath=//*[@class="dialog-footer"]/button
    sleep    240
    Wait until element is visible    id=acnt_passwd
    close browser
