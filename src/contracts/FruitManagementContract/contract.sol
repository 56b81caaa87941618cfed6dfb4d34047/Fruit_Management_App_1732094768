
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FruitManagementContract is Ownable {
    struct Fruit {
        string name;
        uint256 quantity;
        uint256 price; // in wei
    }

    mapping(uint256 => Fruit) public fruits;
    uint256 public fruitCount;

    event FruitAdded(uint256 indexed id, string name, uint256 quantity, uint256 price);
    event FruitQuantityUpdated(uint256 indexed id, uint256 newQuantity);
    event FruitPriceUpdated(uint256 indexed id, uint256 newPrice);
    event FruitPurchased(uint256 indexed id, address buyer, uint256 quantity);

    error FruitNotFound(uint256 id);
    error InsufficientQuantity(uint256 id, uint256 requested, uint256 available);
    error InsufficientPayment(uint256 required, uint256 sent);

    constructor() Ownable() {}

    function addFruit(string memory _name, uint256 _quantity, uint256 _price) external onlyOwner {
        fruitCount++;
        fruits[fruitCount] = Fruit(_name, _quantity, _price);
        emit FruitAdded(fruitCount, _name, _quantity, _price);
    }

    function updateFruitQuantity(uint256 _id, uint256 _newQuantity) external onlyOwner {
        if (fruits[_id].price == 0) revert FruitNotFound(_id);
        fruits[_id].quantity = _newQuantity;
        emit FruitQuantityUpdated(_id, _newQuantity);
    }

    function updateFruitPrice(uint256 _id, uint256 _newPrice) external onlyOwner {
        if (fruits[_id].price == 0) revert FruitNotFound(_id);
        fruits[_id].price = _newPrice;
        emit FruitPriceUpdated(_id, _newPrice);
    }

    function getFruit(uint256 _id) external view returns (Fruit memory) {
        if (fruits[_id].price == 0) revert FruitNotFound(_id);
        return fruits[_id];
    }

    function buyFruit(uint256 _id, uint256 _quantity) external payable {
        Fruit storage fruit = fruits[_id];
        if (fruit.price == 0) revert FruitNotFound(_id);
        if (fruit.quantity < _quantity) revert InsufficientQuantity(_id, _quantity, fruit.quantity);
        
        uint256 totalCost = fruit.price * _quantity;
        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

        fruit.quantity -= _quantity;
        emit FruitPurchased(_id, msg.sender, _quantity);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // IZKPayClient placeholder functions
    function zkPayClientFunction1() external pure returns (bool) {
        return true;
    }

    function zkPayClientFunction2(uint256 _param) external pure returns (uint256) {
        return _param;
    }

    // IZKPay placeholder functions
    function zkPayFunction1() external pure returns (bool) {
        return true;
    }

    function zkPayFunction2(address _addr) external pure returns (address) {
        return _addr;
    }

    // Additional error handling example
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}
