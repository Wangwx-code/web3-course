package main

import (
	"Dapp/token"
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// Sepolia测试网络配置
	const (
		rpcURL     = "https://eth-sepolia.g.alchemy.com/v2/9W9Yi163qkCs-eM2hBC4E"
		privateKey = "89f4cb5a582d0ae8550c64840bcd685d14e65d386c8bab08c0fc3e31c31b23ab"
		tokenAddr  = "0x5979779D01CcBd38f45A3930FD00E09d6b50b3FF"
	)

	// 1. 连接到Sepolia测试网络
	fmt.Println("=== 连接到Sepolia测试网络 ===")
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		log.Fatal("连接失败:", err)
	}
	defer client.Close()

	// 2. 准备账户
	fmt.Println("\n=== 准备账户 ===")
	key, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		log.Fatal("私钥解析失败:", err)
	}

	fromAddress := crypto.PubkeyToAddress(key.PublicKey)
	fmt.Printf("账户地址: %s\n", fromAddress.Hex())

	// 3. 使用生成的绑定代码创建ERC20合约实例
	fmt.Println("\n=== 创建ERC20合约实例 ===")
	tokenAddress := common.HexToAddress(tokenAddr)

	// 使用abigen生成的NewToken函数创建合约实例
	tokenContract, err := token.NewToken(tokenAddress, client)
	if err != nil {
		log.Fatal("创建合约实例失败:", err)
	}
	fmt.Printf("合约地址: %s\n", tokenAddress.Hex())

	// 4. 调用合约的只读方法
	fmt.Println("\n=== 查询合约信息 ===")

	// 查询代币名称
	name, err := tokenContract.Name(&bind.CallOpts{})
	if err != nil {
		log.Fatal("查询代币名称失败:", err)
	}
	fmt.Printf("代币名称: %s\n", name)

	// 查询代币符号
	symbol, err := tokenContract.Symbol(&bind.CallOpts{})
	if err != nil {
		log.Fatal("查询代币符号失败:", err)
	}
	fmt.Printf("代币符号: %s\n", symbol)

	// 查询代币精度
	decimals, err := tokenContract.Decimals(&bind.CallOpts{})
	if err != nil {
		log.Fatal("查询代币精度失败:", err)
	}
	fmt.Printf("代币精度: %d\n", decimals)

	// 查询总供应量
	totalSupply, err := tokenContract.TotalSupply(&bind.CallOpts{})
	if err != nil {
		log.Fatal("查询总供应量失败:", err)
	}
	fmt.Printf("总供应量: %s\n", totalSupply.String())

	// 查询账户余额
	balance, err := tokenContract.BalanceOf(&bind.CallOpts{}, fromAddress)
	if err != nil {
		log.Fatal("查询余额失败:", err)
	}
	fmt.Printf("账户余额: %s %s\n", balance.String(), symbol)

	// 5. 发送交易调用合约的写方法
	fmt.Println("\n=== 发送ERC20代币转账交易 ===")

	// 创建交易认证
	chainID, err := client.ChainID(context.Background())
	if err != nil {
		log.Fatal("获取链ID失败:", err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(key, chainID)
	if err != nil {
		log.Fatal("创建交易者失败:", err)
	}

	// 设置交易参数
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal("获取nonce失败:", err)
	}
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0) // 代币转账不需要发送ETH

	// 获取Gas价格
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal("获取Gas价格失败:", err)
	}
	auth.GasPrice = gasPrice
	auth.GasLimit = uint64(100000) // 设置足够的Gas限制

	// 转账到目标地址
	toAddress := common.HexToAddress("0x7f2ccbe8b8debda1527c587452b609bd35308c78")
	amount := big.NewInt(1000000) // 转账1,000,000个代币 (假设代币精度为18)

	fmt.Printf("转账到: %s\n", toAddress.Hex())
	fmt.Printf("转账金额: %s %s\n", amount.String(), symbol)

	// 调用合约的transfer方法
	tx, err := tokenContract.Transfer(auth, toAddress, amount)
	if err != nil {
		log.Fatal("调用transfer方法失败:", err)
	}

	fmt.Printf("✅ 代币转账交易已发送!\n")
	fmt.Printf("交易哈希: %s\n", tx.Hash().Hex())
	fmt.Printf("可以在 https://sepolia.etherscan.io/tx/%s 查看交易状态\n", tx.Hash().Hex())
}
