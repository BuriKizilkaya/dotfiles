.SILENT:

wsl:
	sudo ansible-playbook -i inventory.yml wsl-playbook.yml

linux:
	sudo ansible-playbook -i inventory.yml linux-playbook.yml

windows:
	ansible-playbook -i inventory.yml windows-playbook.yml