> **Note**
Containers will not be distributed/accessible at this time. Those may be later, but this is still a work in progress.
> 
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=bordenitllc_ubi-container-hardening&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=bordenitllc_ubi-container-hardening)


# REPO GOALS
Our repository aims to showcase a streamlined workflow for crafting containers sourced from diverse public repositories using fortified UBI8 containers. We harness the robustness of these containers to spawn additional application containers, focusing solely on the modified Dockerfiles to optimize efficiency. Rather than reinventing the wheel, we tap into existing solutions and leverage publicly available repositories from RedHatOfficial to align with STIG standards. For testing, we utilize resources such as Scap Compliance Checker. However, it's essential to acknowledge the challenge of achieving 100% STIG compliance with RHEL 8 STIGs for containers. Due to inherent limitations—like the absence of critical components such as sshd, auditd, systemd, and the shared kernel with the underlying OS—we anticipate a significantly lower compliance rate, potentially around 40% when applying the overal RHEL 8 OS STIG to a container.

# Containers Currently Building
|APP OR OS      | BUILT FROM CONTAINER    | PUSHED TO (Latest) | PUSHED TO (GITHUB_SHA} |
| ------------- | ----------------------- | ------------------ | ---------------------- |
| UBI8 | registry.access.redhat.com/ubi8/ubi:8.9  | docker.io/bordenit/ubi8-ubi-8-9:latest  | docker.io/bordenit/ubi8-ubi-8-9:${GITHUB_SHA}  |
| UBI8 | registry.access.redhat.com/ubi8/openjdk-17 | docker.io/bordenit/ubi8-openjdk-17:latest |  docker.io/bordenit/ubi8-openjdk-17:${GITHUB_SHA}   |
| Jenkins | docker.io/bordenit/ubi8-openjdk-17:latest | docker.io/bordenit/jenkins-ubi8-openjdk-17:latest  | docker.io/bordenit/jenkins-ubi8-openjdk-17:${GITHUB_SHA}|

# REFERENCE FOR ENABLING FIPS MODE IN A CONTAINER
It's worth noting that podman automatically enables FIPS mode if the underlying OS has FIPS enabled. Additionally, the fips-mode-setup command is ineffective within containers for enabling or checking FIPS mode. Refer to the following link for details:
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/using-the-system-wide-cryptographic-policies_security-hardening#enabling-fips-mode-in-a-container_using-the-system-wide-cryptographic-policies

# ADDITIONAL DISCLAIMERS BEYOND LICENSE
While many of the measures outlined may seem essential, their necessity diminishes in certain scenarios. For instance, running containers as non-root, implementing FIPS, and enforcing proper security contexts in Kubernetes deployments can mitigate the need for most OS STIGs in the container. This is because a significant portion of OS STIGs revolve around auditing user actions within a system—an aspect irrelevant in containerized environments where actions like ssh login or systemd operations are absent. Moreover, containers utilize the kernel from the underlying OS they run on, limiting the feasibility of certain configurations within containers. While RedHat has made strides in hardening containers, there persists a belief in some communities that containers should adhere to OS-level STIGs, although this may be a dated approach. There's a pressing need for container-specific STIGs, though such initiatives have yet to be undertaken. Existing solutions like IronBank offer some hardening capabilities, yet they often lack depth, particularly in securing application components like Tomcat. Many publicly available resources in IronBank are based on surface-level OS dependencies, leading to redundant repositories rather than leveraging open-source resources to their fullest potential. Embracing the RedHat Official method to STIG RHEL 8 yields comparable overall container STIG scores for the OS relative to solutions like IronBank, and is a vendor direct solution that needs no inventiveness. By not redoing entire vendor repositories, a better focus can be put on application specific STIGs that are much more relevant in a container to protect web or application ingress for example..
