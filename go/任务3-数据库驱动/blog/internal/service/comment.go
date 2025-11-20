package service

import (
	"blog/internal/model"
	"blog/internal/repository"
	"errors"
)

type CommentService interface {
	Save(comment *model.Comment) error
}

type commentService struct {
	repo repository.CommentRepository
}

func (c commentService) Save(comment *model.Comment) error {
	if comment.PostId == 0 {
		return errors.New("需要制定PostId")
	}
	return c.repo.Create(comment)
}

func NewCommentService() CommentService {
	return commentService{repo: repository.NewCommentRepository()}
}
