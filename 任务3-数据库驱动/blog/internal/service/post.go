package service

import (
	"blog/internal/model"
	"blog/internal/repository"
	"errors"
)

type PostService interface {
	Save(post *model.Post) error
	GetPostByUserId(id uint) []model.Post
}

type postService struct {
	repo repository.PostRepository
}

func (p postService) GetPostByUserId(id uint) []model.Post {
	return p.repo.GetPostByUserId(id)
}

func (p postService) Save(post *model.Post) error {
	if post.UserId == 0 {
		return errors.New("需要指定UserId")
	}
	return p.repo.Create(post)
}

func NewPostService() PostService {
	return postService{repository.NewPostRepository()}
}
