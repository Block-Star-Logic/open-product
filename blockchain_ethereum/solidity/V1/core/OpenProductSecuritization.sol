// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.15;


import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureCore.sol";


import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesDerivativesAdmin.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";


import "https://github.com/Block-Star-Logic/open-register/blob/a14334297b2953d3531001bb8624239866d346be/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";


import "../interfaces/IOpenProductSecuritization.sol";

contract OpenProductSecuritization is OpenRolesSecureCore, IOpenVersion, IOpenRolesManaged, IOpenProductSecuritization {  

    IOpenRegister registry; 
    IOpenRolesDerivativesAdmin iorda; 

    uint256 version                     = 3; 
    string name                         = "RESERVED_OPEN_PRODUCT_SECURITIZATION"; 

    string registerCA                   = "RESERVED_OPEN_REGISTER_CORE";
    string roleManagerCA                = "RESERVED_OPEN_ROLES_CORE";

    string dappProductManagerRole       = "DAPP_PRODUCT_MANAGER_ROLE";

    string openAdminRole                = "RESERVED_OPEN_ADMIN_ROLE";

    string productType                  = "OPEN_PRODUCT_TYPE";

    string [] roleNames                 = [dappProductManagerRole, openAdminRole]; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    // Derivative roles

    string productManagerRole           = "PRODUCT_MANAGER_ROLE";

    string [] productLocalRoles         = [productManagerRole];
    mapping(string=>string[]) productManagementFunctionsForProductByRole;
    

    constructor(address _registryAddress, string memory _dapp) OpenRolesSecureCore(_dapp) { 
        
        registry = IOpenRegister(_registryAddress);
        
        setRoleManager(registry.getAddress(roleManagerCA));
       
        iorda = IOpenRolesDerivativesAdmin(roleManager.getDerivativeContractsAdmin(registry.getDapp()));   
        
        addConfigurationItem(_registryAddress);   
        
        addConfigurationItem(address(roleManager));   
        
        addConfigurationItem(address(iorda));   
        
        addConfigurationItem(name, self, version);
        
        initDefaultFunctionsForRoles();
        initDerivativeFunctionsForRoles();       
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name;
    }
    function getDefaultRoles() override view external returns (string [] memory _roleNames){
        return roleNames; 
    }

    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    } 

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address       
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));
        iorda = IOpenRolesDerivativesAdmin(roleManager.getDerivativeContractsAdmin(registry.getDapp()));   
        
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));   
        addConfigurationItem(address(iorda));   
        return true; 
    }

    function secureProduct(address _product) external returns (bool _productSecured){
        require(isSecure(dappProductManagerRole, "secureProduct")," dapp admin only ");
        registry.registerDerivativeAddress(_product, productType );

        iorda.addDerivativeContract(_product, productType);        
        
        iorda.addRolesForDerivativeContract(_product, productLocalRoles);
        for(uint x = 0; x < productLocalRoles.length; x++){
            iorda.addFunctionsForRoleForDerivativeContract(_product, productLocalRoles[x], productManagementFunctionsForProductByRole[productLocalRoles[x]]);
        }
        return true; 
    }
//====================================== INTERNAL ======================================

    function initDefaultFunctionsForRoles() internal returns (bool _initiated) {
        hasDefaultFunctionsByRole[dappProductManagerRole] = true;    
        defaultFunctionsByRole[dappProductManagerRole].push("secureProduct");

        hasDefaultFunctionsByRole[openAdminRole] = true; 
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");
        return true; 
    }

    function initDerivativeFunctionsForRoles() internal returns (bool _initiated) {
        productManagementFunctionsForProductByRole[productManagerRole].push("setFeatureUINTValue");
        productManagementFunctionsForProductByRole[productManagerRole].push("setFeatureSTRValue");
        productManagementFunctionsForProductByRole[productManagerRole].push("setFeatureADDRESSValue");
        productManagementFunctionsForProductByRole[productManagerRole].push("removeFeatureValue");
        productManagementFunctionsForProductByRole[productManagerRole].push("setPrice");
        productManagementFunctionsForProductByRole[productManagerRole].push("setFeatureFee");
        productManagementFunctionsForProductByRole[productManagerRole].push("addFeatureManager");
        productManagementFunctionsForProductByRole[productManagerRole].push("removeFeatureManager");
        return true; 
    }


}