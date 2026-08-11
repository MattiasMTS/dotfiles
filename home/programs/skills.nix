# Single shared source of Agent Skills.
#
# This file fetches the upstream skill repositories once and exposes the
# resulting store paths as an attrset (skill name -> store path). It is
# imported by claude-code, codex and amp so the skill definitions and the
# pinned revs/hashes live in exactly one place.
{ pkgs }:
let
  gcxSetup = import ./gcx.nix { inherit pkgs; };
  clickhouse-agent-skills = pkgs.fetchFromGitHub {
    owner = "ClickHouse";
    repo = "agent-skills";
    rev = "main";
    hash = "sha256-5QwMvgOlqVZwCNwNNNt2CwtM6dk+Fww1EjagA9fezVQ=";
  };
  duckdb-skills = pkgs.fetchFromGitHub {
    owner = "duckdb";
    repo = "duckdb-skills";
    rev = "main";
    hash = "sha256-13dPimt/Gf7coSQe6q1vF7yQwSUoTJSucP9URAxf9VA=";
  };
  temporal-developer-skill = pkgs.fetchFromGitHub {
    owner = "temporalio";
    repo = "skill-temporal-developer";
    rev = "main";
    hash = "sha256-fB3sn8X3GL1sCWy3HrejLHf+tIbFAC9M5WYBM5gPTsA=";
  };
  google-skills = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "skills";
    rev = "fc4af872e9ce7fba5d4f9502081f027419fff5bd";
    hash = "sha256-YFNSCWqglkXw9EPraXu+wW6X2b28/DqWsh4tVEz9MgU=";
  };
  gcloudSkill = name: "${google-skills}/skills/cloud/${name}";
  gcxSkill = name: {
    inherit name;
    value = "${gcxSetup.skills}/${name}";
  };
in
{
  clickhouse-best-practices = "${clickhouse-agent-skills}/skills/clickhouse-best-practices";
  duckdb-attach-db = "${duckdb-skills}/skills/attach-db";
  duckdb-docs = "${duckdb-skills}/skills/duckdb-docs";
  duckdb-install = "${duckdb-skills}/skills/install-duckdb";
  duckdb-query = "${duckdb-skills}/skills/query";
  duckdb-read-file = "${duckdb-skills}/skills/read-file";
  duckdb-read-memories = "${duckdb-skills}/skills/read-memories";
  temporal-developer = "${temporal-developer-skill}";

  # Google Cloud skills (github.com/google/skills).
  gcloud = gcloudSkill "gcloud";
  bigquery-basics = gcloudSkill "bigquery-basics";
  cloud-run-basics = gcloudSkill "cloud-run-basics";
  cloud-sql-basics = gcloudSkill "cloud-sql-basics";
  gke-basics = gcloudSkill "gke-basics";

  # Well-Architected Framework
  google-cloud-waf-security = gcloudSkill "google-cloud-waf-security";
  google-cloud-waf-reliability = gcloudSkill "google-cloud-waf-reliability";
  google-cloud-waf-cost-optimization = gcloudSkill "google-cloud-waf-cost-optimization";
  google-cloud-waf-operational-excellence = gcloudSkill "google-cloud-waf-operational-excellence";
  google-cloud-waf-performance-optimization = gcloudSkill "google-cloud-waf-performance-optimization";
  google-cloud-waf-sustainability = gcloudSkill "google-cloud-waf-sustainability";
}
// builtins.listToAttrs (
  map gcxSkill [
    "agento11y"
    "agento11y-instrument"
    "agento11y-prod-setup"
    "agento11y-test-starter"
    "create-dashboard"
    "debug-with-grafana"
    "diagnose-entity-graph"
    "gcx"
    "gcx-demo"
    "gcx-observability"
    "generate-resource-stubs"
    "import-dashboards"
    "investigate-alert"
    "manage-dashboards"
    "oncall-triage"
    "scaffold-project"
    "setup-gcx"
    "slo-check-status"
    "slo-investigate"
    "slo-manage"
    "slo-optimize"
    "synth-check-status"
    "synth-investigate-check"
    "synth-manage-checks"
  ]
)
