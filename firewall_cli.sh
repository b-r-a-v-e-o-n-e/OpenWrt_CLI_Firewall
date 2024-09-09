#!/bin/bash

# Terminal colors (ANSI codes)
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
DARK_GREEN='\033[0;36m'
ORANGE='\033[0;33m'
DARK_BLUE='\033[0;34m'
GRAY='\033[1;30m'
NC='\033[0m' # No color

# Function to view existing rules and zones in /etc/config/firewall
view_firewall_config() {
    echo -e "${DARK_GREEN}Viewing existing rules and zones from /etc/config/firewall:${NC}"
    uci show firewall
}

# Function to add a new Port Forward rule with zone and/or IP
add_port_forward() {
    echo -e "${GREEN}Adding a new Port Forward rule.${NC}"
    read -p "Enter rule name: " rule_name
    read -p "Enter external port: " ext_port
    read -p "Enter internal IP address: " int_ip
    read -p "Enter internal port: " int_port

    # Choose Source zone and/or IP address
    echo "Choose Source zone and/or IP address:"
    read -p "Enter zone name (leave empty if not needed): " src_zone
    read -p "Enter IP address (leave empty if not needed): " src_ip

    # Adding a new port forward rule in /etc/config/firewall
    uci add firewall redirect
    uci set firewall.@redirect[-1].name="$rule_name"
    
    # Set zone if provided
    if [ ! -z "$src_zone" ]; then
        uci set firewall.@redirect[-1].src="$src_zone"
    fi
    # Set IP if provided
    if [ ! -z "$src_ip" ]; then
        uci set firewall.@redirect[-1].src_ip="$src_ip"
    fi

    uci set firewall.@redirect[-1].src_dport="$ext_port"
    uci set firewall.@redirect[-1].dest_ip="$int_ip"
    uci set firewall.@redirect[-1].dest_port="$int_port"
    
    # Choose multiple protocols
    echo "Select protocols, separated by commas (TCP, UDP, ICMP, IGMP or ANY for all): "
    read -p "Protocols: " proto
    if [[ "$proto" == "ANY" || "$proto" == "any" ]]; then
        uci set firewall.@redirect[-1].proto="all"
    else
        proto_list=$(echo "$proto" | tr ',' ' ') # Replace commas with spaces for UCI
        uci set firewall.@redirect[-1].proto="$proto_list"
    fi

    uci commit firewall
    /etc/init.d/firewall reload

    echo -e "${GREEN}Port Forward rule added: $ext_port -> $int_ip:$int_port with protocols $proto.${NC}"
}

# Function to delete a Port Forward rule
delete_port_forward() {
    echo -e "${RED}Deleting a Port Forward rule.${NC}"
    echo "Viewing existing Port Forward rules:"
    uci show firewall | grep '=redirect'
    read -p "Enter the section to delete (e.g. @redirect[0]): " section

    # Delete the Port Forward rule from /etc/config/firewall
    uci delete firewall."$section"
    uci commit firewall
    /etc/init.d/firewall reload

    echo -e "${RED}Port Forward rule deleted: $section${NC}"
}

# Function to add a new Traffic Rule with zone and/or IP
add_traffic_rule() {
    echo -e "${GREEN}Adding a new Traffic Rule.${NC}"
    read -p "Enter rule name: " rule_name

    # Choose Source zone and/or IP address
    echo "Choose Source zone and/or IP address:"
    read -p "Enter zone name (leave empty if not needed): " src_zone
    read -p "Enter IP address (leave empty if not needed): " src_ip

    # Choose Destination zone and/or IP address
    echo "Choose Destination zone and/or IP address:"
    read -p "Enter zone name (leave empty if not needed): " dst_zone
    read -p "Enter IP address (leave empty if not needed): " dst_ip

    read -p "Enter port: " port
    read -p "Select action (ACCEPT, REJECT, DROP): " action

    # Choose multiple protocols
    echo "Select protocols, separated by commas (TCP, UDP, ICMP, IGMP or ANY for all): "
    read -p "Protocols: " proto
    if [[ "$proto" == "ANY" || "$proto" == "any" ]]; then
        proto="all"
    else
        proto=$(echo "$proto" | tr ',' ' ') # Replace commas with spaces for UCI
    fi

    # Adding a new traffic rule in /etc/config/firewall
    uci add firewall rule
    uci set firewall.@rule[-1].name="$rule_name"

    # Set source IP and/or zone
    if [ ! -z "$src_zone" ]; then
        uci set firewall.@rule[-1].src="$src_zone"
    fi
    if [ ! -z "$src_ip" ]; then
        uci set firewall.@rule[-1].src_ip="$src_ip"
    fi

    # Set destination IP and/or zone
    if [ ! -z "$dst_zone" ]; then
        uci set firewall.@rule[-1].dest="$dst_zone"
    fi
    if [ ! -z "$dst_ip" ]; then
        uci set firewall.@rule[-1].dest_ip="$dst_ip"
    fi

    uci set firewall.@rule[-1].dest_port="$port"
    uci set firewall.@rule[-1].proto="$proto"
    uci set firewall.@rule[-1].target="$action"

    uci commit firewall
    /etc/init.d/firewall reload

    echo -e "${GREEN}Traffic Rule added: $rule_name with action $action and protocols $proto.${NC}"
}

# Function to delete a Traffic Rule
delete_traffic_rule() {
    echo -e "${RED}Deleting a Traffic Rule.${NC}"
    echo "Viewing existing Traffic Rules:"
    uci show firewall | grep '=rule'
    read -p "Enter the section to delete (e.g. @rule[0]): " section

    # Delete the Traffic Rule from /etc/config/firewall
    uci delete firewall."$section"
    uci commit firewall
    /etc/init.d/firewall reload

    echo -e "${RED}Traffic Rule deleted: $section${NC}"
}

# Function to reorder rules
reorder_rule() {
    echo -e "${ORANGE}Reordering rules.${NC}"
    echo "Viewing existing rules:"
    uci show firewall | grep '=rule\|=redirect'

    read -p "Enter the section to reorder (e.g. @rule[0], @redirect[1]): " section
    read -p "Enter the new position of the rule (e.g. 1 for first position): " new_position

    uci reorder firewall."$section"="$new_position"
    uci commit firewall
    /etc/init.d/firewall reload

    echo -e "${ORANGE}Rule $section has been moved to position $new_position.${NC}"
}

# Function to view existing Port Forward rules with names
view_port_forward() {
    echo -e "${DARK_GREEN}Viewing current Port Forward rules (redirects):${NC}"
    uci show firewall | grep '=redirect'
    echo "Rule names:"
    uci show firewall | grep '.name='
}

# Function to view existing Traffic Rules with names
view_traffic_rules() {
    echo -e "${DARK_GREEN}Viewing current Traffic Rules:${NC}"
    uci show firewall | grep '=rule'
    echo "Rule names:"
    uci show firewall | grep '.name='
}

# Function to view existing NAT rules with names
view_nat_rules() {
    echo -e "${DARK_GREEN}Viewing NAT rules (includes Port Forward):${NC}"
    uci show firewall | grep '=redirect'
    echo "Rule names:"
    uci show firewall | grep '.name='
}

# Function to view existing zones with names
view_zones() {
    echo -e "${DARK_GREEN}Viewing existing zones (zone sections):${NC}"
    uci show firewall | grep '=zone'
    echo "Zone names:"
    uci show firewall | grep '.name='
}

# Function to reset firewall configuration
reset_firewall() {
    echo -e "${DARK_BLUE}Resetting firewall configuration (clearing all rules and settings)...${NC}"
    uci revert firewall
    uci commit firewall
    /etc/init.d/firewall reload
    echo -e "${DARK_BLUE}Firewall configuration has been reset to the default state.${NC}"
}

# Main menu with colors
while true; do
    echo -e "${LIGHT_BLUE}----------------------------------------"
    echo -e "   Firewall Management - OpenWrt"
    echo -e "----------------------------------------${NC}"
    echo -e "${DARK_GREEN}1) View firewall configuration${NC}"
    echo -e "${GREEN}2) Add Port Forward rule${NC}"
    echo -e "${RED}3) Delete Port Forward rule${NC}"
    echo -e "${GREEN}4) Add Traffic Rule${NC}"
    echo -e "${RED}5) Delete Traffic Rule${NC}"
    echo -e "${DARK_GREEN}6) View Port Forward rules${NC}"
    echo -e "${DARK_GREEN}7) View Traffic Rules${NC}"
    echo -e "${DARK_GREEN}8) View NAT rules${NC}"
    echo -e "${DARK_GREEN}9) View zones${NC}"
    echo -e "${ORANGE}10) Reorder rules${NC}"
    echo -e "${DARK_BLUE}11) Reset firewall${NC}"
    echo -e "${GRAY}12) Exit${NC}"
    echo -e "${LIGHT_BLUE}----------------------------------------${NC}"
    read -p "Select an option: " choice

    case $choice in
        1)
            view_firewall_config
            ;;
        2)
            add_port_forward
            ;;
        3)
            delete_port_forward
            ;;
        4)
            add_traffic_rule
            ;;
        5)
            delete_traffic_rule
            ;;
        6)
            view_port_forward
            ;;
        7)
            view_traffic_rules
            ;;
        8)
            view_nat_rules
            ;;
        9)
            view_zones
            ;;
        10)
            reorder_rule
            ;;
        11)
            reset_firewall
            ;;
        12)
            echo -e "${GRAY}Exiting...${NC}"
            break
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
done
