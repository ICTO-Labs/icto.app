import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

import FactoryRegistryTypes "FactoryRegistryTypes";
import AuditTypes "../audit/AuditTypes";
import MicroserviceTypes "../microservices/MicroserviceTypes";

module FactoryRegistryService {

    // Import types for convenience
    type State = FactoryRegistryTypes.State;
    type StableState = FactoryRegistryTypes.StableState;
    type UserCanisterRelationships = FactoryRegistryTypes.UserCanisterRelationships;
    type CanisterRelationship = FactoryRegistryTypes.CanisterRelationship;
    type RelationshipType = FactoryRegistryTypes.RelationshipType;
    type RelationshipMetadata = FactoryRegistryTypes.RelationshipMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type FactoryRegistryError = FactoryRegistryTypes.FactoryRegistryError;
    type UserRelationshipQuery = FactoryRegistryTypes.UserRelationshipQuery;
    type RelationshipQuery = FactoryRegistryTypes.RelationshipQuery;
    type UserRelationshipMap = FactoryRegistryTypes.UserRelationshipMap;

    // ==================================================================================================
    // INTEGRATION FUNCTION FOR DEPLOYMENT FLOW
    // ==================================================================================================

    // Simple batch add relationships - called from main.mo deployment flow
    public func batchAddUserRelationshipsFromFlow(
        state: State,
        microserviceState: MicroserviceTypes.State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        name: Text,
        description: ?Text
    ) : FactoryRegistryResult<()> {
        let metadata : RelationshipMetadata = {
            name = name;
            description = description;
            additionalData = null;
        };
        
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // ==================================================================================================
    // STATE MANAGEMENT
    // ==================================================================================================

    public func initState() : State {
        FactoryRegistryTypes.emptyState()
    };

    public func fromStableState(stableState: StableState) : State {
        let state = FactoryRegistryTypes.emptyState();
        
        // Restore user relationships
        for ((userText, userRelationships) in stableState.userRelationships.vals()) {
            state.userRelationships := Trie.put(
                state.userRelationships,
                {key = userText; hash = Text.hash(userText)},
                Text.equal,
                userRelationships
            ).0;
        };

        state
    };

    public func toStableState(state: State) : StableState {
        {
            userRelationships = Iter.toArray(Trie.iter(state.userRelationships));
        }
    };

    // ==================================================================================================
    // USER RELATIONSHIP FUNCTIONS  
    // ==================================================================================================

    // Internal add user relationship (no authorization check - for backend calls)
    private func addUserRelationshipInternal(
        state: State,
        microserviceState: MicroserviceTypes.State,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        let userText = Principal.toText(user);
        Debug.print("Adding user relationship: " # userText # " to " # Principal.toText(canisterId));
        
        // Get existing user relationships or create empty array
        let existingRelationships = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?relationships) { relationships };
            case null { [] };
        };
        
        // Get factory principal for this relationship using enhanced auth (no caller = internal call)
        let factoryPrincipal = switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, null, relationshipType)) {
            case (#Ok(principal)) { principal };
            case (#Err(error)) { 
                // For internal calls, we should handle missing factory gracefully
                Debug.print("⚠️  Factory not found for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType) # " - Error: " # debug_show(error));
                // Return error instead of using invalid hardcoded principal
                return #Err(#FactoryTypeNotSupported("No factory registered for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType)));
            };
        };
        Debug.print("✅ Factory principal: " # Principal.toText(factoryPrincipal));

        // Create new relationship
        let newRelationship = FactoryRegistryTypes.createCanisterRelationship(
            canisterId,
            relationshipType,
            factoryPrincipal,
            metadata
        );
        
        // Add relationship to user's list
        let updatedRelationships = FactoryRegistryTypes.addRelationshipToUser(existingRelationships, newRelationship);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedRelationships
        ).0;
        
        #Ok(())
    };

    // Public add user relationship (with potential authorization for external calls)
    public func addUserRelationship(
        state: State,
        microserviceState: MicroserviceTypes.State,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        // For now, just delegate to internal - can add authorization later if needed
        addUserRelationshipInternal(state, microserviceState, user, relationshipType, canisterId, metadata)
    };

    // Internal batch add (from backend deployment flow - no authorization needed)
    public func batchAddUserRelationships(
        state: State,
        microserviceState: MicroserviceTypes.State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        for (user in users.vals()) {
            switch (addUserRelationshipInternal(state, microserviceState, user, relationshipType, canisterId, metadata)) {
                case (#Err(error)) {
                    return #Err(error);
                };
                case (#Ok(_)) {
                    // Continue to next user
                };
            };
        };
        
        #Ok(())
    };

    // External batch add (with authorization check)
    public func batchAddUserRelationshipsExternal(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized factory for this relationship type using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                // Authorization already checked in getFactoryForRelationshipTypeWithAuth
                Debug.print("✅ Authorized caller " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        // Use internal version for actual work
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // ==================================================================================================
    // PUBLIC CALLBACK API FOR EXTERNAL CONTRACTS
    // ==================================================================================================

    // Public API for external contracts to update user relationships
    public func updateUserRelationships(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized factory for this relationship type using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                Debug.print("✅ Authorized external call from " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        // Add relationships for all users
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // Remove user relationship
    public func removeUserRelationship(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                Debug.print("✅ Authorized removal by " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        let userText = Principal.toText(user);
        
        // Get existing user relationships
        let existingRelationships = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?relationships) { relationships };
            case null { return #Err(#NotFound("User has no relationships to remove")) };
        };
        
        // Remove relationship from list
        let updatedRelationships = FactoryRegistryTypes.removeRelationshipFromUser(existingRelationships, canisterId, relationshipType);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedRelationships
        ).0;
        
        #Ok(())
    };

    // ==================================================================================================
    // QUERY FUNCTIONS
    // ==================================================================================================

    // Get all relationships for a user (new detailed format)
    public func getUserCanisterRelationships(
        state: State,
        queryObj: UserRelationshipQuery
    ) : FactoryRegistryResult<UserCanisterRelationships> {
        
        let userText = Principal.toText(queryObj.user);
        
        switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?userRelationships) {
                var filteredRelationships = userRelationships;
                
                // Filter by relationship type if specified
                switch (queryObj.relationshipType) {
                    case (?relationshipType) {
                        filteredRelationships := FactoryRegistryTypes.filterRelationshipsByType(filteredRelationships, relationshipType);
                    };
                    case null { };
                };
                
                // Filter by active status
                filteredRelationships := FactoryRegistryTypes.filterRelationshipsByActive(filteredRelationships, queryObj.includeInactive);
                
                #Ok(filteredRelationships)
            };
            case null {
                #Ok([])
            };
        };
    };

    // Get user relationships in backward-compatible format
    public func getUserRelationships(
        state: State,
        queryObj: UserRelationshipQuery
    ) : FactoryRegistryResult<UserRelationshipMap> {
        
        switch (getUserCanisterRelationships(state, queryObj)) {
            case (#Ok(relationships)) {
                let compatibleMap = FactoryRegistryTypes.toBackwardCompatibleMap(relationships);
                #Ok(compatibleMap)
            };
            case (#Err(error)) {
                #Err(error)
            };
        }
    };

    // Query relationships with filters
    public func queryRelationships(
        state: State,
        queryObj: RelationshipQuery
    ) : FactoryRegistryResult<[CanisterRelationship]> {
        
        let buffer = Buffer.Buffer<CanisterRelationship>(0);
        let limit = Option.get(queryObj.limit, 100); // Default limit
        let offset = Option.get(queryObj.offset, 0);
        var count = 0;
        var skipped = 0;

        label relationshipLoop for ((_, userRelationships) in Trie.iter(state.userRelationships)) {
            if (count >= limit) break relationshipLoop;
            
            for (relationship in userRelationships.vals()) {
                if (count >= limit) break relationshipLoop;
                
                // Apply filters
                var matches = true;
                
                // Filter by relationship type
                switch (queryObj.relationshipType) {
                    case (?filterType) {
                        if (relationship.relationshipType != filterType) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by canister ID
                switch (queryObj.canisterId) {
                    case (?filterCanister) {
                        if (relationship.canisterId != filterCanister) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by factory principal
                switch (queryObj.factoryPrincipal) {
                    case (?filterFactory) {
                        if (relationship.factoryPrincipal != filterFactory) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by active status
                switch (queryObj.isActive) {
                    case (?filterActive) {
                        if (relationship.isActive != filterActive) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                if (matches) {
                    if (skipped < offset) {
                        skipped += 1;
                    } else {
                        buffer.add(relationship);
                        count += 1;
                    };
                };
            };
        };
        
        #Ok(Buffer.toArray(buffer))
    };

    // ==================================================================================================
    // UTILITY FUNCTIONS
    // ==================================================================================================

    // Enhanced version that checks microservice state and caller authorization
    private func getFactoryForRelationshipTypeWithAuth(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: ?Principal,
        relationshipType: RelationshipType
    ) : FactoryRegistryResult<Principal> {
        
        // First try to get factory from microservice state based on relationship type
        switch (microserviceState.canisterIds) {
            case (?canisterIds) {
                let factoryPrincipal = switch (relationshipType) {
                    case (#DistributionRecipient) { canisterIds.distributionFactory };
                    case (#LaunchpadParticipant) { canisterIds.launchpadFactory };
                    case (#DAOMember) { canisterIds.templateFactory }; // DAOs use template factory
                    case (#MultisigSigner) { canisterIds.templateFactory }; // Multisigs use template factory
                };
                
                switch (factoryPrincipal) {
                    case (?factory) {
                        // If caller is provided, verify authorization
                        switch (caller) {
                            case (?callerPrincipal) {
                                // Check if caller is the factory itself (authorized)
                                if (callerPrincipal == factory) {
                                    return #Ok(factory);
                                };
                                
                                // Check if caller is another microservice (authorized)
                                if (isCallerInMicroservices(canisterIds, callerPrincipal)) {
                                    return #Ok(factory);
                                };
                                
// Unauthorized caller
                                return #Err(#Unauthorized("Caller not authorized to update relationships"));
                            };
                            case null {
                                // Internal call (no caller check needed)
                                return #Ok(factory);
                            };
                        };
                    };
                    case null {
                        // Factory not found in microservice state
                        return #Err(#NotFound("Factory not configured for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType)));
                    };
                };
            };
            case null {
                // Microservice not configured yet
                return #Err(#NotFound("Microservice configuration not found"));
            };
        };
    };

    // Helper function to check if caller is in microservice canister IDs
    private func isCallerInMicroservices(canisterIds: MicroserviceTypes.CanisterIds, caller: Principal) : Bool {
        // Check against all microservice canister IDs
        switch (canisterIds.distributionFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.tokenFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.templateFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.lockFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.launchpadFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        false
    };


}