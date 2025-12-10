*** Settings ***
Library           Collections
Library           DateTime
Library           String
Library           OperatingSystem
Library           Selenium2Library
Resource          keyword/Variable.robot
Resource          keyword/telnet_ssh_sample.robot
Resource          keyword/kw_gui_setup.robot
Library           ./library/pytestlink.py
Library           ./library/pyserial.py
Variables         ./config/topology/Myvariable.yaml

