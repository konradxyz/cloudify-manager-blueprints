#!/bin/bash -e

. $(ctx download-resource "components/utils")
. $(ctx download-resource "components/elasticsearch/scripts/configure_es")


export ES_JAVA_OPRT=$(ctx node properties es_java_opts)  # (e.g. "-Xmx1024m -Xms1024m")
export ELASTICHSEARCH_SOURCE_URL=$(ctx node properties es_rpm_source_url)  # (e.g. "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.3.tar.gz")

export ELASTICSEARCH_PORT="9200"
export ELASTICSEARCH_HOME="/opt/elasticsearch"
export ELASTICSEARCH_LOG_PATH="/var/log/cloudify/elasticsearch"
export ELASTICSEARCH_CONF_PATH="/etc/elasticsearch"


ctx logger info "Installing Elasticsearch..."

copy_notice "elasticsearch"
create_dir ${ELASTICSEARCH_HOME}
create_dir ${ELASTICSEARCH_LOG_PATH}

yum_install ${ELASTICHSEARCH_SOURCE_URL}

blueprint_es_conf_path="components/elasticsearch/config/elasticsearch.yml"
destination_es_conf_path="${ELASTICSEARCH_CONF_PATH}/elasticsearch.yml"
ctx logger info "Deploying Elasticsearch Config file ${blueprint_es_conf_path} to ${destination_es_conf_path}..."
tmp_es_conf_path=$(ctx download-resource ${blueprint_es_conf_path})
sudo mv ${tmp_es_conf_path} ${destination_es_conf_path}

ctx logger info "Starting Elasticsearch for configuration purposes..."
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

ctx logger info "Waiting for Elasticsearch to become available..."
wait_for_port "${ELASTICSEARCH_PORT}"

ctx logger info "Configuring Elasticsearch Indices, Mappings, etc..."
# per a function in configure_es
configure_elasticsearch

ctx logger info "Killing Elasticsearch..."
sudo systemctl stop elasticsearch.service

ctx logger info "Installing Elasticsearch Curator..."
# sudo rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch

# curepo="/etc/yum.repos.d/curator.repo"
# cat << EOF | sudo tee $curepo > /dev/null
# "[curator-3]
# name=CentOS/RHEL 7 repository for Elasticsearch Curator 3.x packages
# baseurl=http://packages.elasticsearch.org/curator/3/centos/7
# gpgcheck=1
# gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
# enabled=1"
# EOF

# yum_install python-elasticsearch-curator

# yum install --downloadonly --downloaddir=/tmp python-elasticsearch-curator

install_module "elasticsearch-curator==3.2.0"

rotator_script=$(ctx download-resource components/scripts/elasticsearch_logsevents_index_rotator)

ctx logger info "Configuring Elasticsearch Index Rotation cronjob for logstash-YYYY.mm.dd index patterns..."
sudo mv ${rotator_script} /etc/cron.daily/elasticsearch_logsevents_index_rotator
sudo chmod +x /etc/cron.daily/elasticsearch_logsevents_index_rotator