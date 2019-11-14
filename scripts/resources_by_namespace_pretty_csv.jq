import "i8-helpers" as i8 {"search": ["~/.rhmi/utils/lib/jq","~/repos/rhmi-utils/lib/jq"]};

def getPodResources:
  [.pods[] | {
    ns: .metadata.namespace,
    pod: .metadata.name,
    containers: .spec.containers[]
  } | {
    ns,
    pod,
    container: .containers.name,
    requests: .containers.resources.requests | i8::normalizeResources,
    limits: .containers.resources.limits | i8::normalizeResources
  }
  ];

def getPodUsages:
  [."pod-metrics"[] | {
    ns: .metadata.namespace,
    pod: .metadata.name,
    containers: .containers[]
  } | {
    ns,
    pod,
    container: .containers.name,
    usage: .containers.usage | i8::normalizeResources
   }
   ];

i8::process |
getPodResources as $pods |
getPodUsages as $usages |
[i8::leftJoin($pods; $usages; "\(.ns) \(.pod) \(.container)")] |
group_by(.ns) |
map({
  ns: .[0].ns,
  cpu_real: [.[].usage.cpu] | add | (if . then .|i8::roundit else . end),
  mem_real: [.[].usage.memory] | add | i8::prettyBytes,
  cpu_req: [.[].requests?.cpu] | add | (if . then .|i8::roundit else . end),
  mem_req: [.[].requests?.memory] | add | i8::prettyBytes,
  cpu_lim: [.[].limits?.cpu] | add | (if . then .|i8::roundit else . end),
  mem_lim: [.[].limits?.memory] | add | i8::prettyBytes
}) | (.[0] | to_entries | map(.key)), (.[] | [.[]]) | @csv
#  |= [ ["x","y","z"] ] + . |
# @csv

