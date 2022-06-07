#!/bin/bash

#/usr/local/bin/aptos-operational-tool generate-key --encoding hex --key-type x25519 --key-file ~/.aptos/key/private-key.txt
if [ -f ~/.aptos/key/private-key.txt ]; then
    echo ""
else 
    /usr/local/bin/aptos-operational-tool generate-key --encoding hex --key-type x25519 --key-file ~/.aptos/key/private-key.txt
fi

if [ -f ~/.aptos/config/peer-info.yaml ]; then
    echo ""
else 
    /usr/local/bin/aptos-operational-tool extract-peer-from-file --encoding hex --key-file ~/.aptos/key/private-key.txt --output-file ~/.aptos/config/peer-info.yaml &>/dev/null
fi

#/usr/local/bin/aptos-operational-tool extract-peer-from-file --encoding hex --key-file ~/.aptos/key/private-key.txt --output-file ~/.aptos/config/peer-info.yaml &>/dev/null
cp ~/aptos-core/config/src/config/test_data/public_full_node.yaml ~/.aptos/config/
wget -q -O /opt/aptos/etc/genesis.blob https://devnet.aptoslabs.com/genesis.blob
wget -q -O /opt/aptos/etc/waypoint.txt https://devnet.aptoslabs.com/waypoint.txt
PRIVKEY=$(cat ~/.aptos/key/private-key.txt)
PEER=$(sed -n 2p ~/.aptos/config/peer-info.yaml | sed 's/.$//')
sed -i "s/genesis_file_location: .*/genesis_file_location: \"\/opt\/aptos\/etc\/genesis.blob\"/" $HOME/.aptos/config/public_full_node.yaml
sed -i "s/from_file: .*/from_file: \"\/opt\/aptos\/etc\/waypoint.txt\"/" $HOME/.aptos/config/public_full_node.yaml
sleep 2 
sed -i.bak -e "s/127.0.0.1/0.0.0.0/" $HOME/.aptos/config/public_full_node.yaml
sed -i '/listen_address: \"*\"/a\
      identity:\
        type: "from_config"\
        key: "'$PRIVKEY'"\
        peer_id: "'$PEER'"' $HOME/.aptos/config/public_full_node.yaml
