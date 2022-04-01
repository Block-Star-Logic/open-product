// SPDX-License-Identifier: APACHE-2.0

pragma solidity >=0.8.0 <0.9.0;


import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";
import "https://github.com/Block-Star-Logic/open-roles/blob/e7813857f186df0043c84f0cca42478584abe09c/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecure.sol";
import "https://github.com/Block-Star-Logic/open-register/blob/03fb07e69bfdfaa6a396a063988034de65bdab3d/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";

import "../interfaces/IOpenProductCore.sol";

import "./OpenProduct.sol";
 

contract OpenProductCore is OpenRolesSecure, IOpenRolesManaged, IOpenProductCore { 

    using LOpenUtilities for address; 

    string name = "RESERVED_OPEN_PRODUCT_CORE"; 
    uint256 version = 1; 

    string openAdminRole = "RESERVED_OPEN_ADMIN_ROLE";
    string productManagerRole = "PRODUCT_MANAGER_ROLE";

    address[] products; 
    uint256[] ids; 

    string registerCA       = "RESERVED_OPEN_REGISTER";
    string roleManagerCA    = "RESERVED_OPEN_ROLES";

    address registryAddress; 
    IOpenRegister registry; 

    string [] roleNames = [openAdminRole, productManagerRole]; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    uint256 productIndex = 1; 
    
    mapping(address=>bool) knownByProductAddress; 
    mapping(uint256=>bool) knownByProductId; 
    mapping(uint256=>address) productAddressByProductId; 
    mapping(string=>address[]) productsByName; 


    //@ todo implement full product management features 
    constructor (address _registryAddress){ 
        registryAddress = _registryAddress;   
        registry = IOpenRegister(_registryAddress); 
        setRoleManager(registry.getAddress(roleManagerCA));
        addConfigurationItem(_registryAddress);
        addConfigurationItem(address(roleManager));
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

    function getProduct(uint256 _productId) override view external returns (address _productAddress){
        return productAddressByProductId[_productId];
    } 

    function getProducts() override view external returns (address [] memory _products) {
        return products; 
    }

    function findProducts(string memory _name) view external returns (address [] memory _product) {
        return productsByName[_name];
    }

    function getProductIds() override  view external returns (uint256[] memory _ids) {
        return ids; 
    }

    function isVerified(address _product) override view external returns (bool _verified){
        return knownByProductAddress[_product];
    }

    function createProduct(string memory _name, uint256 _price, string memory _currency, address _erc20) override external returns (address _productAddress) {
        require(isSecure(productManagerRole, "createProduct")," admin only ");
        uint256 productId_ = productIndex++;
        ids.push(productId_);
        _productAddress = address(new OpenProduct(address(registry), productId_, _name, _price, _currency, _erc20));
        productsByName[_name].push(_productAddress); 
        addProductInternal(_productAddress);
        return _productAddress;
    }

    function removeProduct(address _productAddress) override external returns (bool _removed) {
        require(isSecure(productManagerRole, "removeProduct")," admin only ");
        return removeProductInternal(_productAddress);        
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address                   
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));    
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));         
        return true; 
    }
    // ====================================== INTERNAL =================================================

    function addProductInternal(address _productAddress) internal returns (bool _added) {
        OpenProduct product = OpenProduct(_productAddress);
        uint256 productId_ = product.getId(); 
        if(!knownByProductId[productId_]){
            productAddressByProductId[product.getId()] = _productAddress; 
            products.push(_productAddress);
            knownByProductAddress[_productAddress] = true; 
            knownByProductId[productId_] = true; 
            return true; 
        }
        return false; 
    }

    function removeProductInternal(address _productAddress) internal returns (bool _removed){
        OpenProduct product = OpenProduct(_productAddress);
        uint256 productId_ = product.getId(); 
        if(knownByProductId[productId_]){
            delete productAddressByProductId[product.getId()]; 
            _productAddress.remove(products);
            delete knownByProductAddress[_productAddress]; 
            delete knownByProductId[productId_]; 
            return true; 
        }
        return false; 
    }

    function initDefaulFunctionsForRole() internal returns (bool _initiated){
        hasDefaultFunctionsByRole[openAdminRole] = true; 
        hasDefaultFunctionsByRole[productManagerRole] = true; 
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");
        defaultFunctionsByRole[productManagerRole].push("createProduct");
        defaultFunctionsByRole[productManagerRole].push("removeProduct");
        return true;
    }
}