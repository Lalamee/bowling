package ru.bowling.bowlingapp.Security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Getter
public class UserPrincipal implements UserDetails {

    private final Long id;
    private final String phone;
    private final String password;
    private final boolean isActive;
    private final Collection<? extends GrantedAuthority> authorities;

    private UserPrincipal(Long id,
                          String phone,
                          String password,
                          boolean isActive,
                          Collection<? extends GrantedAuthority> authorities) {
        this.id = id;
        this.phone = phone;
        this.password = password;
        this.isActive = isActive;
        this.authorities = authorities == null ? Collections.emptyList() : authorities;
    }

    public static UserPrincipal create(User user) {
        if (user == null) {
            return new UserPrincipal(null, null, null, false, Collections.emptyList());
        }
        boolean active = Boolean.TRUE.equals(user.getIsActive());
        Role role = user.getRole();
        Collection<? extends GrantedAuthority> authorities = buildAuthorities(role != null ? role.getName() : null);
        return new UserPrincipal(
                user.getUserId(),
                user.getPhone(),
                user.getPasswordHash(),
                active,
                authorities
        );
    }

    public static UserPrincipal fromClaims(Long userId, String phone, String roleName) {
        return new UserPrincipal(
                userId,
                phone,
                null,
                true,
                buildAuthorities(roleName)
        );
    }

    private static Collection<? extends GrantedAuthority> buildAuthorities(String roleName) {
        if (roleName == null || roleName.isBlank()) {
            return Collections.emptyList();
        }

        String normalized = roleName.trim().toUpperCase(Locale.ROOT);
        Set<String> authorityKeys = new LinkedHashSet<>();
        authorityKeys.add("ROLE_" + normalized);

        if ("HEAD_MECHANIC".equals(normalized)) {
            authorityKeys.add("ROLE_MANAGER");
        }

        List<GrantedAuthority> result = new ArrayList<>(authorityKeys.size());
        for (String key : authorityKeys) {
            result.add(new SimpleGrantedAuthority(key));
        }
        return Collections.unmodifiableList(result);
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return phone;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return isActive;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return isActive;
    }
}
