model ModSeborgCSTRorg
  // Model of ORiGinal Seborg CSTR in ode form
  // author: 	Bernt Lie
  //			University of Southeast Norway
  //			November 7, 2017
  //
  // Parameters
  parameter Real V = 100 "Reactor volume, L";
  parameter Real rho = 1e3 "Liquid density, g/L";
  parameter Real a = 1 "Stoichiometric constant, -";
  parameter Real EdR = 8750 "Activation temperature, K";
  parameter Real k0 = exp(EdR/350) "Pre-exponential factor, 1/min";
  parameter Real cph = 0.239 "Specific heat capacity of mixture, J.g-1.K-1";
  parameter Real DrHt = -5e4 "Molar enthalpy of reaction, J/mol";
  parameter Real UA = 5e4 "Heat transfer parameter, J/(min.K)";

  // Initial state parameters
  parameter Real cA0 = 0.5 "Initial concentration of A, mol/L";
  parameter Real T0 = 350 "Initial temperature, K";
  // Declaring variables
  // -- states
  Real cA(start = cA0, fixed = true) "Initializing concentration of A in reactor, mol/L";
  Real T(start = T0, fixed = true) "Initializing temperature in reactor, K";
  // -- auxiliary variables
  Real r "Rate of reaction, mol/(L.s)";
  Real k "Reaction 'constant', ...";
  Real Qd "Heat flow rate, J/min";
  // -- input variables
  input Real Vdi "Volumetric flow rate through reactor, L/min";
  input Real cAi "Influent molar concentration of A, mol/L";
  input Real Ti "Influent temperature, K";
  input Real Tc "Cooling temperature', K";
  // -- output variables
  output Real y_T "Reactor temperature, K";
  // Equations constituting the model
equation
  // Differential equations
  der(cA) = Vdi*(cAi-cA)/V- a*r;
  der(T) = Vdi*(Ti-T)/V + (-DrHt)*r/(rho*cph) + Qd/(rho*V*cph);
  // Algebraic equations
  r = k*cA^a;
  k = k0*exp(-EdR/T);
  Qd = UA*(Tc-T);
  // Outputs
  y_T = T;
end ModSeborgCSTRorg;