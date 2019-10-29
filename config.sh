#! /bin/bash

dhcp_file_name="dhcpd.conf"
interfaces_file_name="interfaces.conf"
squid_file_name="squid.conf"

faixa_ip_adm="10.10.10"
faixa_ip_vis="10.10.20"

ip_server="172.19.150.69"

cria_configs()
{    
    echo "criando nova configuracao interfaces\n\n"
    touch "$interfaces_file_name"

    escreve_interfaces_config;

    echo "removendo configuracao dhcp anterior\n\n"
    rm -f /etc/dhcp/$dhcp_file_name

    echo "criando nova configuracao dhcp\n\n"
    touch "$dhcp_file_name"

    escreve_dhcp_config;

    echo "configurando iptables\n\n"
    configura_iptables;

    echo "criando nova configuraçao squid\n\n"
    touch "$squid_file_name"
}

escreve_interfaces_config()
{
    echo "escrevendo interfaces config\n\n"
    log1="$interfaces_file_name"

    echo "auto lo\n" >> $log1
    echo "iface lo inet loopback\n\n" >> $log1 

    echo "auto eth0\n\n" >> $log1 

    echo "iface eth0 inet static\n" >> $log1 
        echo "address $ip_server\n" >> $log1 
        echo "netmask 255.255.255.0\n" >> $log1 
        echo "gateway 192.168.1.1\n" >> $log1 
        echo "# dns-nameservers 172.29.0.11 172.29.0.10\n\n" >> $log1 

    echo "auto eth1\n\n" >> $log1 

    echo "iface eth1 inet static\n" >> $log1 
        echo "address 10.10.10.254\n" >> $log1 
        echo "netmask 255.255.255.0\n\n" >> $log1 

    echo "auto eth2\n\n" >> $log1 

    echo "iface eth2 inet static\n" >> $log1 
        echo "address 10.10.20.254\n" >> $log1 
        echo "netmask 255.255.255.0" >> $log1 

    sleep 1
    echo "interfaces config criada\n\n"

    move_interfaces_config;
}

move_interfaces_config()
{    
    echo "movendo interfaces config\n\n"
    mv $interfaces_file_name /etc/network/

    reinicia_interfaces_service;
}

reinicia_dhcp_service()
{
    echo "reiniciando service\n\n"
    sudo service networking restart;
}

escreve_dhcp_config()
{
    echo "escrevendo config\n\n"
    log2="$dhcp_file_name"
    echo "ddns-update-style none;\n\n" >> $log2

    echo "authoritative;\n\n" >> $log2

    echo "subnet $faixa_ip_adm.0 netmask 255.255.255.0 {\n" >> $log2
    
    echo "   range $faixa_ip_adm.1 $faixa_ip_adm.255;\n\n" >> $log2

    echo "   option subnet-mask 255.255.255.0;\n\n" >> $log2

    echo "   option broadcast-address $faixa_ip_adm.255;\n\n" >> $log2
    
    echo "   option routers $ip_server;\n\n" >> $log2

    echo "   option domain-name-servers 8.8.8.8, 8.8.4.4;\n" >> $log2
    echo "}\n\n" >> $log2

    echo "subnet $faixa_ip_vis.0 netmask 255.255.255.0 {\n" >> $log2
    
    echo "   range $faixa_ip_vis.1 $faixa_ip_vis.255;\n\n" >> $log2

    echo "   option subnet-mask 255.255.255.0;\n\n" >> $log2

    echo "   option broadcast-address $faixa_ip_vis.255;\n\n" >> $log2
    
    echo "   option routers $ip_server;\n\n" >> $log2

    echo "   default-lease-time 600;\n\n" >> $log2

    echo "   max-lease-time 86400;\n\n" >> $log2

    echo "   option domain-name-servers 8.8.8.8, 8.8.4.4;\n" >> $log2
    echo "}\n\n" >> $log2
    
    sleep 1
    echo "config criada\n\n"

    move_dhcp_config;
}

move_dhcp_config()
{    
    echo "movendo dhcp config\n\n"
    mv $dhcp_file_name /etc/dhcp/

    reinicia_dhcp_service;
}

reinicia_dhcp_service()
{
    echo "reiniciando service\n\n"
    sudo systemctl enable isc-dhcp-server;
    sudo systemctl restart isc-dhcp-server;
}

configura_iptables()
{
    # zera regras firewall
    sudo iptables -F

    # fecha todas as conexoes
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT DROP

    # libera acesso para visitante
    sudo iptables -A INPUT -p tcp --dport 22 -m iprange --src-range $faixa_ip_vis.1-$faixa_ip_vis.255 -j ACCEPT

    # libera acesso para visitante
    sudo iptables -A INPUT -p tcp --dport 22 -m iprange --src-range $faixa_ip_adm.1-$faixa_ip_adm.255 -j ACCEPT

    # fecha qualquer acesso ssh
    sudo iptables -A INPUT -p tcp --dport 22 -j DROP

    # bloqueia ping
    sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

    # Elimina os pacotes invalidos
    sudo iptables -A INPUT -m state --state INVALID -j DROP 

    # libera conexoes estabelecidas 
    sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED,NEW -j ACCEPT
    sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED,NEW -j ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT

    echo "salvando configuracao iptables\n\n"
    sleep 1

    # salva a configuracao
    sudo iptables-save 
}

configura_squid()
{

    # TODO
    move_squid_config;
}

move_squid_config()
{
    echo "movendo squid config\n\n"
    mv $squid_file_name /etc/squid/

    reinicia_squid_service;
}

reinicia_squid_service() 
{
    # TODO
}

cria_configs;
