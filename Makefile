.PHONY: build
build:
	docker build -t ardrahan/duplicity .

.PHONY: clean
clean:
	docker rmi -f ardrahan/duplicity
