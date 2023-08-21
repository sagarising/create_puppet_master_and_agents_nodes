output "ssh_command_master_node" {
  value       = "ssh -i ~/.ssh/${aws_key_pair.this.key_name}.pem ubuntu@${aws_instance.master.public_dns}"
  description = "ssh command for connecting to the master node"
}

output "ssh_command_agent_nodes" {
  value       = <<-SSHCOMMAND
  %{for dns in aws_instance.agents[*].public_dns}
  ssh -i ~/.ssh/${aws_key_pair.this.key_name}.pem ubuntu@${dns}
  %{endfor}
  SSHCOMMAND
  description = "ssh command for connect to the agent nodes"
}
