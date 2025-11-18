package repository

import (
	"blog/internal/config"
	"blog/internal/model"

	"gorm.io/gorm"
)

type UserRepository interface {
	Create(user *model.User) error
}

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository() UserRepository {
	db := config.GetDB()
	err := db.AutoMigrate(&model.User{})
	if err != nil {
		return nil
	}
	return userRepository{db}
}

func (r userRepository) Create(user *model.User) error {
	return r.db.Create(user).Error
}
