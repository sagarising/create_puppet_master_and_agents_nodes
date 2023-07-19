output "ssh_command_master_node" {
  value       = <<-SSHCOMMAND
  ssh ubuntu@${aws_instance.master.public_dns}
  SSHCOMMAND
  description = "ssh command for connecting to the master node"
}

output "ssh_command_agent_nodes" {
  value       = <<-SSHCOMMAND
  %{for dns in aws_instance.agents[*].public_dns}
  ssh ubuntu@${dns}
  %{endfor}
  SSHCOMMAND
  description = "ssh command for connect to the agent nodes"
}
