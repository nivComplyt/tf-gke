import os
import re

input_file = os.path.join(os.path.dirname(os.path.dirname(__file__)), "variables.tf")
output_file = os.path.join(os.path.dirname(os.path.dirname(__file__)), "README.md")

def parse_variables(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    modules = {}
    current_module = None

    for line in content.splitlines():
        module_match = re.match(r"#+\s*(.*?)\s*#+", line)
        if module_match:
            current_module = module_match.group(1).strip()
            modules[current_module] = []

        var_match = re.match(r'variable\s+\"(.*?)\"', line)
        if var_match:
            var_name = var_match.group(1)
            modules[current_module].append({"name": var_name, "description": "", "default": ""})

        desc_match = re.match(r'\s*description\s*=\s*\"(.*?)\"', line)
        if desc_match and current_module:
            if modules[current_module]:
                modules[current_module][-1]["description"] = desc_match.group(1)

        default_match = re.match(r'\s*default\s*=\s*(.*)', line)
        if default_match and current_module:
            if modules[current_module]:
                default_val = default_match.group(1).strip()
                modules[current_module][-1]["default"] = default_val

    return modules

def generate_readme(modules, output_path):
    with open(output_path, 'w') as f:
        f.write("# Terraform Infrastructure Configuration\n\n")
        f.write("This document lists all available configuration variables for setting up the infrastructure modules.\n\n")

        for module, variables in modules.items():
            f.write(f"## {module}\n\n")
            f.write("| Variable Name | Description | Example Value |\n")
            f.write("| :------------ | :----------- | :------------ |\n")

            for var in variables:
                description = var["description"] or "(No description provided)"
                default = var["default"] or "(No default)"
                f.write(f"| {var['name']} | {description} | {default} |\n")

            f.write("\n---\n\n")

if __name__ == "__main__":
    modules = parse_variables(input_file)
    generate_readme(modules, output_file)
    print(f"README generated successfully at {output_file}.")