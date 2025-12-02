package main

import (
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// 配置
	const (
		rpcURL     = "https://eth-sepolia.g.alchemy.com/v2/9W9Yi163qkCs-eM2hBC4E"
		privateKey = "89f4cb5a582d0ae8550c64840bcd685d14e65d386c8bab08c0fc3e31c31b23ab"
		toAddress  = "0x7f2ccbe8b8debda1527c587452b609bd35308c78"
	)

	// 1. 连接到Sepolia测试网络
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		log.Fatal("连接失败:", err)
	}
	defer client.Close()

	// 2. 查询最新区块信息
	fmt.Println("=== 查询最新区块 ===")
	blockNumber, err := client.BlockNumber(context.Background())
	if err != nil {
		log.Fatal("查询区块号失败:", err)
	}
	fmt.Printf("最新区块号: %d\n", blockNumber)

	block, err := client.BlockByNumber(context.Background(), big.NewInt(int64(blockNumber)))
	if err != nil {
		log.Fatal("查询区块失败:", err)
	}
	fmt.Printf("区块哈希: %s\n", block.Hash().Hex())
	fmt.Printf("时间戳: %d\n", block.Time())
	fmt.Printf("交易数量: %d\n", len(block.Transactions()))

	// 3. 发送ETH交易
	fmt.Println("\n=== 发送ETH交易 ===")
	key, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		log.Fatal("私钥解析失败:", err)
	}

	fromAddress := crypto.PubkeyToAddress(key.PublicKey)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal("获取nonce失败:", err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal("获取Gas价格失败:", err)
	}

	// 转账0.01 ETH
	value := big.NewInt(10000000000000000) // 0.01 ETH in wei
	to := common.HexToAddress(toAddress)

	tx := types.NewTx(&types.LegacyTx{
		Nonce:    nonce,
		To:       &to,
		Value:    value,
		Gas:      21000,
		GasPrice: gasPrice,
		Data:     nil,
	})

	chainID, err := client.ChainID(context.Background())
	if err != nil {
		log.Fatal("获取链ID失败:", err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), key)
	if err != nil {
		log.Fatal("签名失败:", err)
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal("发送交易失败:", err)
	}

	fmt.Printf("交易已发送，哈希: %s\n", signedTx.Hash().Hex())
}
