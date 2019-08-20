from kubernetes import client, config
import datetime
from datetime import timezone

# Configs can be set in Configuration class directly or using helper utility
config.load_kube_config()
v1 = client.CoreV1Api()

class Kubernetes():
    def get_nodes(self): #TODO: Add 'Roles' column
        ret = v1.list_node()
        for i in ret.items:
            print("NAME\tSTATUS\tROLES\tAGE\tVERSION")
            print("%s\t%s\t%s\t%s" % (i.metadata.name,
                                      i.status.conditions[-1].type,
                                      #TODO: format AGE like 5d20h
                                      (datetime.datetime.now(timezone.utc) - i.metadata.creation_timestamp),
                                      i.status.node_info.kubelet_version))

    def get_pods(self, namespace): #TODO: Add 'Ready' column
        ret = v1.list_namespaced_pod(namespace)
        for i in ret.items:
            print("%s\t%s\t%s\t%s" % (i.metadata.name, i.status.phase, i.status.container_statuses[0].restart_count,
                                      # TODO: format AGE like 5d20h
                                      (datetime.datetime.now(timezone.utc) - i.metadata.creation_timestamp)))

    def get_all_pods(self):
        v1 = client.CoreV1Api()
        print("Listing pods with their IPs:")
        ret = v1.list_pod_for_all_namespaces(watch=False)
        for i in ret.items:
            print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))


