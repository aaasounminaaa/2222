module_list = ["busan_iam", "busan_Governance", "busan_CICD", "chungnam_Governance", "chungnam_CICD", "chungnam_network", "daejeon_serverless", "daejeon_Governance", "daejeon_EKS","gwangju_Network","gwangju_CICD","gwangju_EKS","gyeongbuk_CICD","gyeongbuk_WAF","gyeongbuk_Elastic_stack","Jeju_Serverless","Jeju_Governanace","Jeju_Secure_networking","seoul_CDN","seoul_Governance","seoul_IAM"]

# Function to generate Terraform command
def generate_terraform_command(modules):
    var_string = ', '.join([f'"{module}"' for module in modules])
    return f'terraform apply --auto-approve -var=\'module_names=[{var_string}]\''.replace("\"", "\\\"")
module_list_lower = [module.lower() for module in module_list]

# Function to prompt user and select modules
def select_modules_from_list():
    print("Available modules:")
    for index, module in enumerate(module_list):
        print(f"{index + 1}. {module}")
    
    selected_modules = []
    while True:
        selection = input("Enter the number of the module to select (or 'done' to finish): ").strip().lower()
        if selection == 'done':
            break
        elif selection.isdigit():
            index = int(selection) - 1
            if 0 <= index < len(module_list):
                module_name = module_list[index]
                if module_name not in selected_modules:
                    selected_modules.append(module_name)
                    print(f"Added {module_name} to selected modules.")
                else:
                    print(f"{module_name} is already selected.")
            else:
                print("Invalid module number. Please enter a valid number.")
        else:
            print("Invalid input. Please enter a number or 'done'.")
    
    return selected_modules

# Example usage:
selected_modules = select_modules_from_list()
if selected_modules:
    command = generate_terraform_command(selected_modules)
    print(f"Generated command: \n{command}")
else:
    print("No modules selected. Exiting.")