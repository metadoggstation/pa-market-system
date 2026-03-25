// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetadoggStationPA is ERC1155, Ownable {
    
    struct Service {
        string name;       // サービス名（例：コードレビュー、HP回復）
        uint256 price;     // 価格 (ETH/BTC相当のトークン)
        uint256 stock;     // 在庫数
        address provider;  // サービス提供者（リモートワーカー）
    }

    // 各PA（ステーションID）ごとの販売リスト
    mapping(uint256 => Service) public stationServices;

    constructor() ERC1155("https://api.metadogg.com/metadata/{id}.json") Ownable(msg.sender) {}

    // サービスを出店（Play to Dev）
    // PAのオーナーが自分のスキルをNFTとして並べる
    function listService(uint256 stationId, string memory name, uint256 price, uint256 stock) public {
        stationServices[stationId] = Service(name, price, stock, msg.sender);
    }

    // サービスの購入
    // プレイヤーが実際にそのPAのマスに到達した際に呼び出される
    function buyService(uint256 stationId, uint256 amount) public payable {
        Service storage service = stationServices[stationId];
        require(msg.value >= service.price * amount, "Insufficient payment");
        require(service.stock >= amount, "Out of stock");

        service.stock -= amount;
        
        // 売上の分配（80%は提供者へ、20%はPAの維持・開発費へ）
        uint256 fee = (msg.value * 20) / 100;
        payable(service.provider).transfer(msg.value - fee);
        // ※feeはコントラクトに蓄積され、PAのアップグレード（EV増設等）に使用
        
        // サービス利用証明としてNFTをミント
        _mint(msg.sender, stationId, amount, "");
    }
}
