// SPDX-License-Identifier: APACHE-2.0

pragma solidity ^0.8.15;

import "../interfaces/IOpenProductList.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureCore.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";

import "https://github.com/Block-Star-Logic/open-register/blob/7b680903d8bb0443b9626a137e30a4d6bb1f6e43/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";

contract OpenProductList is OpenRolesSecureCore, IOpenVersion, IOpenRolesManaged, IOpenProductList {

    using LOpenUtilities for address; 

    string constant name                         = "OPEN_PRODUCT_LIST";
    uint256 constant version                     = 2; 

    string constant registerCA                   = "RESERVED_OPEN_REGISTER_CORE";
    string constant roleManagerCA                = "RESERVED_OPEN_ROLES_CORE";

    IOpenRegister registry; 
    
    string constant openBusinessAdminRole        = "RESERVED_OPEN_BUSINESS_ADMIN_ROLE";

    string constant openAdminRole                = "RESERVED_OPEN_ADMIN_ROLE";

    string [] roleNames = [openAdminRole, openBusinessAdminRole];
    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    string listType;
    string listName; 

    address [] addresses; 
    mapping(address=>bool) list; 

    constructor(address _registryAddress, string memory _dapp, string memory _listType, string memory _listName) OpenRolesSecureCore(_dapp) {
        registry = IOpenRegister(_registryAddress);
        
        setRoleManager(registry.getAddress(roleManagerCA));
        
        listName = _listName;
        listType = _listType; 
    
        addConfigurationItem(_registryAddress);   
        
        addConfigurationItem(address(roleManager));   
        
        addConfigurationItem(name, self, version);
        
        initDefaultFunctionsForRoles();

    }   

    function getVersion() override pure external returns (uint256 _version){
        return version; 
    }

    function getName() override pure external returns (string memory _contractName){
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

    function isOnList(address _address) view external returns (bool _onList){
        return list[_address];
    }

    function getListType() view external returns (string memory _listType){
        return listType; 
    }

    function getListName() view external returns (string memory _listName) {
        return listName; 
    }

    function getAddresses() view external returns (address [] memory _addresses) {
        return addresses; 
    }

    function addAddress(address _address) external returns (bool _added ) {
        require(isSecure(openBusinessAdminRole, "addAddress") || isSecure(openAdminRole, "addAddress")," admin only "); 
        addresses.push(_address);
        list[_address] = true; 
        return true;
    }

    function removeAddress(address _address) external returns (bool _removed) {
        require(isSecure(openBusinessAdminRole,"removeAddress") || isSecure(openAdminRole, "removeAddress")," admin only "); 
        addresses = _address.remove(addresses);
        delete list[_address];
        return true; 
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address       
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));
       
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));   
        return true; 
    }
    
    //====================================== INTERNAL ======================================

    function initDefaultFunctionsForRoles() internal returns (bool _initiated) {
        hasDefaultFunctionsByRole[openAdminRole] = true; 

        defaultFunctionsByRole[openAdminRole].push("addAddress"); 
        defaultFunctionsByRole[openAdminRole].push("removeAddress"); 
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");

        hasDefaultFunctionsByRole[openBusinessAdminRole] = true; 

        defaultFunctionsByRole[openBusinessAdminRole].push("addAddress"); 
        defaultFunctionsByRole[openBusinessAdminRole].push("removeAddress");         
        return true; 
    }
}