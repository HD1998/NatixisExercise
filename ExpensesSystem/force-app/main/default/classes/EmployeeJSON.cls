public class EmployeeJSON {
    
    public class EmployeesList {
        public List<EmployeeItem> employees;    //o nome da variável tem de ser "employees" porque é o valor que está no ficheiro txt (que contém o JSON)
    }
    
    public class EmployeeItem {
        public String name;
        public String lastName;
        public String idNum;
        public String idType;
        public String nationality;
        public String gender;
        public String birthdate;
        public String email;
    }
}
