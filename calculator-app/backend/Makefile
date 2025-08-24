lint:
	ruff check .
	flake8 .
	black --check .
	mypy .

test:
	pytest --cov=. tests/
