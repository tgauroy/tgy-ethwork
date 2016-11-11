FROM centos:7
MAINTAINER Thomas GAUROY <thomas.gauroy@gmail.com> 

ENV DATA_DIR /root/.ethereum
ARG NETWORKID=42
ENV SUBNET 42.42.42

RUN mkdir $DATA_DIR

COPY artifacts/genesis.json $DATA_DIR/genesis.json
COPY artifacts/credentials.* $DATA_DIR/
COPY artifacts/key.* /root/
COPY artifacts/static-nodes.json /root/.ethereum/static-nodes.json


RUN yum install golang -y &&  \
	yum install gmp-devel -y  && \
	yum install git -y 

RUN  git clone https://github.com/ethereum/go-ethereum

RUN yum install make -y


RUN cd /go-ethereum &&  make geth 

RUN yum -y  install wget

RUN wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm && rpm -ivh epel-release-7-8.noarch.rpm

RUN for i in miner buyer seller carrier inspector bank1 bank2; do \
    /go-ethereum/build/bin/geth --password $DATA_DIR/credentials.$i --datadir=$DATA_DIR account new > $DATA_DIR/$i.id; \
    sed -i "s/Address: {//g" $DATA_DIR/$i.id; \
    sed -i "s/}//g" $DATA_DIR/$i.id; \
    sed -i "s/$i/0x$(cat $DATA_DIR/$i.id)/" $DATA_DIR/genesis.json; \
    done

RUN /go-ethereum/build/bin/geth --networkid $NETWORKID init $DATA_DIR/genesis.json && \
    yum -y install nodejs npm --enablerepo=epel  && \
    yum -y install python && \
    git clone https://github.com/ing-bank/eth-netstats &&\
    cd /eth-netstats && npm install &&\
    cd /eth-netstats && npm install -g grunt-cli &&\
    cd /eth-netstats && grunt && \
    cd &&\
    git clone https://github.com/ing-bank/eth-net-intelligence-api.git /eth-net-intelligence-api

COPY artifacts/app.json /eth-net-intelligence-api

RUN cd /eth-net-intelligence-api &&\
    npm install -d &&\
    npm install pm2 -g

ENV WS_SECRET g3heim

EXPOSE 3000
EXPOSE 8545
EXPOSE 30303
COPY artifacts/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
