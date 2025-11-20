package config

import (
	"blog/internal/pkg/database"

	"gorm.io/gorm"
)

var db *gorm.DB

func databaseConfig() database.DataSourceConfig {
	return database.DataSourceConfig{
		Host:     "127.0.0.1",
		Port:     "3306",
		User:     "root",
		Password: "deepwise",
		DBName:   "metaNode",
	}
}

func GetDB() *gorm.DB {
	if db != nil {
		return db
	}
	var err error
	dbConfig := databaseConfig()
	db, err = database.NewMysqlDB(dbConfig)
	if err != nil {
		panic(err)
	}
	return db
}
