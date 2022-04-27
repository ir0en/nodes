#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1


if [ ! $DEFUND_NODENAME ]; then
read -p "Enter node name: " DEFUND_NODENAME
echo 'export DEFUND_NODENAME='\"${DEFUND_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
wget -O go1.18.1.linux-amd64.tar.gz https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && rm go1.18.1.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
rm -rf $HOME/defund
git clone https://github.com/defund-labs/defund
cd defund
make install

defundd init "$DEFUND_NODENAME" --chain-id=defund-private-1

seeds="8e1590558d8fede2f8c9405b7ef550ff455ce842@51.79.30.9:26656,bfffaf3b2c38292bd0aa2a3efe59f210f49b5793@51.91.208.71:26656,106c6974096ca8224f20a85396155979dbd2fb09@198.244.141.176:26656"
#seeds="1b3e596531dd8f36363b13339beed2364900e4c6@104.131.41.157:26656"
peers="111ba4e5ae97d5f294294ea6ca03c17506465ec5@208.68.39.221:26656,b16142de5e7d89ee87f36d3bbdd2c2356ca2509a@75.119.155.248:26656,ad7b2ecb931a926d60d1e034d0e37a83d0e265f1@109.107.181.127:26656,1b827c298f013900476c2eab25ce5ff75a6f8700@178.63.62.212:26656,111ba4e5ae97d5f294294ea6ca03c17506465ec5@208.68.39.221:26656,f114c02efc5aa7ee3ee6733d806a1fae2fbfb66b@5.189.178.222:46656,8980faac5295875a5ecd987a99392b9da56c9848@85.10.216.151:26656,3c3170f0bcbdcc1bef12ed7b92e8e03d634adf4e@65.108.103.236:27656"

sed -i "s/^seeds *=.*/seeds = \"$seeds\"/;" $HOME/.defund/config/config.toml
sed -i "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/;" $HOME/.defund/config/config.toml

#### VALIDATOR ####
sed -i "s/pruning *=.*/pruning = \"custom\"/g" $HOME/.defund/config/app.toml
sed -i "s/pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/g" $HOME/.defund/config/app.toml
sed -i "s/pruning-interval *=.*/pruning-interval = \"10\"/g" $HOME/.defund/config/app.toml
#sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.defund/config/app.toml
sed -i.bak -e "s/indexer *=.*/indexer = \"null\"/g" $HOME/.defund/config/config.toml

wget -O $HOME/.defund/config/genesis.json https://raw.githubusercontent.com/schnetzlerjoe/defund/main/testnet/private/genesis.json
defundd tendermint unsafe-reset-all
wget -O $HOME/.defund/config/addrbook.json https://api.nodes.guru/defund_addrbook.json
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=DeFund Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which defundd) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/defund.service
sudo mv $HOME/defund.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable defund
sudo systemctl restart defund

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service defund status | grep active` =~ "running" ]]; then
  echo -e "Your Defund node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice defund status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your Defund node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
