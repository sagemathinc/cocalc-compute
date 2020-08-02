build:
	docker build -t cocalc-compute .

build-full:
	docker build --no-cache -t cocalc-compute .

push:
	docker tag cocalc-compute:latest sagemathinc/cocalc-compute:latest
	docker push sagemathinc/cocalc-compute:latest
	docker tag cocalc-compute:latest sagemathinc/cocalc-compute:`date -u +'%Y%m%dT%H%M'`
	docker push sagemathinc/cocalc-compute:`date -u +'%Y%m%dT%H%M'`
