import os

pom_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\pom.xml"

with open(pom_path, "r", encoding="utf-8") as f:
    content = f.read()

bom = """
 <dependencyManagement>
  <dependencies>
   <dependency>
    <groupId>org.springframework.modulith</groupId>
    <artifactId>spring-modulith-bom</artifactId>
    <version>1.1.0</version>
    <type>pom</type>
    <scope>import</scope>
   </dependency>
  </dependencies>
 </dependencyManagement>

"""

if "<dependencyManagement>" not in content:
    content = content.replace("<dependencies>", bom + " <dependencies>", 1)

with open(pom_path, "w", encoding="utf-8") as f:
    f.write(content)

print("pom.xml updated with dependencyManagement.")
