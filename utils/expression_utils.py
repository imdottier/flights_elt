import yaml
from pyspark.sql.functions import col

def load_config(config_path: str) -> dict:
    """
    Loads the YAML config from an explicit path provided by the orchestrator.
    """
    with open(config_path, "r") as f:
        return yaml.safe_load(f)

def get_select_expressions(config_dict: dict, layer: str, table_name: str) -> list:
    """
    Builds Spark select expressions based on the provided configuration dictionary.
    """
    rules = config_dict[layer][table_name]
    select_expressions = []

    for c in rules['final_column_order']:
        alias = c.get("alias")
        if alias:
            select_expressions.append(col(c["name"]).alias(alias))
        else:
            select_expressions.append(col(c["name"]))

    return select_expressions

def get_merge_strategy(config_dict: dict, layer: str, table_name: str) -> dict:
    """
    Returns the merge strategy for the given layer and table name.
    """
    return config_dict[layer][table_name]["merge_strategy"]