package main

import (
	"blog/internal/model"
	"blog/internal/service"
	"fmt"

	"github.com/gin-gonic/gin"
)

var userService = service.NewUserService()
var postService = service.NewPostService()
var commentService = service.NewCommentService()

func main() {
	engine := gin.Default()

	engine.POST("/blog/createUser", func(c *gin.Context) {
		user := model.User{}
		err := c.BindJSON(&user)
		if err != nil {
			fmt.Println(err)
			return
		}
		err = userService.Save(&user)
		if err != nil {
			fmt.Println(err)
			return
		}
	})

	engine.POST("/blog/post", func(c *gin.Context) {
		post := model.Post{}
		err := c.BindJSON(&post)
		if err != nil {
			fmt.Println(err)
			return
		}
		err = postService.Save(&post)
		if err != nil {
			fmt.Println(err)
			return
		}
	})

	engine.POST("/blog/comment", func(c *gin.Context) {
		comment := model.Comment{}
		err := c.BindJSON(&comment)
		if err != nil {
			fmt.Println(err)
			return
		}
		err = commentService.Save(&comment)
		if err != nil {
			fmt.Println(err)
			return
		}
	})

	engine.POST("/blog/getPostByUserId", func(c *gin.Context) {
		var jsonData = map[string]uint{}
		err := c.ShouldBindJSON(&jsonData)
		if err != nil {
			return
		}
		// 从查询参数获取 userId
		userId := jsonData["userId"]

		var posts = postService.GetPostByUserId(userId)
		c.JSON(200, posts)
	})

	err := engine.Run()
	if err != nil {
		return
	}

}
