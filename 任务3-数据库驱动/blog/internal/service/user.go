package service

import (
	"blog/internal/model"
	"blog/internal/repository"
)

type UserService interface {
	Save(user *model.User) error
}

type userService struct {
	repo repository.UserRepository
}

func (u userService) Save(user *model.User) error {
	return u.repo.Create(user)
}

func NewUserService() UserService {
	return userService{repository.NewUserRepository()}
}
